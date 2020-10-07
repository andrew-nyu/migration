function evaluateModelFit()

clear all;
close all;
load migrationCounts_2002_2011;
load midasLocations;


quantileMarker = 0.01;
%use just 2002 data for now
%migrationData = reshape(interDistrictMovesMat(:,:,1),64,64);
%popData = reshape(popMat(:,1),64,1);

%average data from 2002 to 2011
popData = mean(popMat,2);
interDistrictMovesMat(isnan(interDistrictMovesMat)) = 0;
migrationData = mean(interDistrictMovesMat,3);

sourcePopWeights = popData * ones(1, 64);
destPopWeights = sourcePopWeights';
jointPopWeights = sourcePopWeights .* destPopWeights;

sourcePopSum = sum(sum(sourcePopWeights));
destPopSum = sum(sum(destPopWeights));
jointPopSum = sum(sum(jointPopWeights));

%one simple metric is the relative # of migrations per source-destination
%pair
fracMigsData = migrationData / sum(sum(migrationData));

%another is the migs per total population
migRateData = migrationData / sum(popData);

%and another is the in/out ratio
inOutData = sum(migrationData) ./ (sum(migrationData'))';

try
    load evaluationOutputs
catch
    fileList = dir('MC*.mat');
    
    %inputListRun = [];
    %outputListRun = [];
    skip = false(length(fileList),1);
    for indexI = 1:length(fileList)
        try
            currentRun = load(fileList(indexI).name);
            fprintf(['Run ' num2str(indexI) ' of ' num2str(length(fileList)) '.\n']);
            
            fracMigsRun = currentRun.output.migrationMatrix / sum(sum(currentRun.output.migrationMatrix));
            migRateRun = currentRun.output.migrationMatrix / size(currentRun.output.agentSummary,1) / 11;  %(this data is 11 years)
            inOutRun = sum(currentRun.output.migrationMatrix) ./ (sum(currentRun.output.migrationMatrix'))';
            
            fracMigsError = sum(sum((fracMigsRun - fracMigsData).^2));
            sourceWeightFracMigsError = sum(sum(((fracMigsRun - fracMigsData).^2).*sourcePopWeights))/sourcePopSum;
            destWeightFracMigsError = sum(sum(((fracMigsRun - fracMigsData).^2).*destPopWeights))/destPopSum;
            jointWeightFracMigsError = sum(sum(((fracMigsRun - fracMigsData).^2).*jointPopWeights))/jointPopSum;
            
            migRateError = sum(sum((migRateRun - migRateData).^2));
            sourceWeightMigRateError = sum(sum(((migRateRun - migRateData).^2).*sourcePopWeights))/sourcePopSum;
            destWeightMigRateError = sum(sum(((migRateRun - migRateData).^2).*destPopWeights))/destPopSum;
            jointWeightMigRateError = sum(sum(((migRateRun - migRateData).^2).*jointPopWeights))/jointPopSum;
            
            fracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), ones(numel(fracMigsRun),1));
            sourceFracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), sourcePopWeights(:));
            destFracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), destPopWeights(:));
            jointFracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), jointPopWeights(:));
            
            migRate_r2 = weightedPearson(migRateRun(:), migRateData(:), ones(numel(migRateRun),1));
            sourceMigRate_r2 = weightedPearson(migRateRun(:), migRateData(:), sourcePopWeights(:));
            destMigRate_r2 = weightedPearson(migRateRun(:), migRateData(:), destPopWeights(:));
            jointMigRate_r2 = weightedPearson(migRateRun(:), migRateData(:), jointPopWeights(:));
            
            inOutError = sum(sum((inOutRun - inOutData).^2));
            popWeightInOutError = sum(sum(((inOutRun - inOutData).^2).*sourcePopWeights))/sourcePopSum;
            inOutError_r2 = weightedPearson(inOutRun(:), inOutData(:), ones(numel(inOutRun),1));
            popInOut_r2 = weightedPearson(inOutRun(:), inOutData(:), sourcePopWeights(:));
            
            %runLevel
            
            currentInputRun = array2table([currentRun.input.parameterValues]','VariableNames',strrep({currentRun.input.parameterNames{:}},'.',''));
            currentOutputRun = table(fracMigsError,sourceWeightFracMigsError, destWeightFracMigsError, jointWeightFracMigsError, ...
                migRateError,sourceWeightMigRateError, destWeightMigRateError, jointWeightMigRateError, ...
                fracMigs_r2, sourceFracMigs_r2, destFracMigs_r2, jointFracMigs_r2, ...
                migRate_r2, sourceMigRate_r2, destMigRate_r2, jointMigRate_r2, ...
                inOutError, popWeightInOutError, inOutError_r2, popInOut_r2, ...
                'VariableNames',{'FracMigsError', 'SourceWeightFracMigsError','DestWeightFracMigsError','JointWeightFracMigsError', ...
                'MigRateError', 'SourceWeightMigRateError','DestWeightMigRateError','JointWeightMigRateError', ...
                'fracMigs_r2', 'sourceFracMigs_r2', 'destFracMigs_r2', 'jointFracMigs_r2', ...
                'migRate_r2', 'sourceMigRate_r2', 'destMigRate_r2', 'jointMigRate_r2', ...
                'inOutError','popWeightInOutError','inOutError_r2','popInOut_r2'});
            inputListRun(indexI,:) = currentInputRun;
            outputListRun(indexI,:) = currentOutputRun;
        catch
            skip(indexI) = true;
        end
        
    end
    
    skip = skip(1:height(inputListRun));
    inputListRun(skip,:) = [];
    outputListRun(skip,:) = [];
    fileList(skip) = [];
    
end

%save evaluationOutputs inputListRun outputListRun fileList

minR2 = quantile(outputListRun.jointFracMigs_r2,[1 - quantileMarker]);
bestInputs = inputListRun(outputListRun.jointFracMigs_r2 >= minR2,:);

expList = dir('experiment_*');
load(expList(1).name);

for indexI = 1:height(mcParams)
    tempIndex = strmatch(strrep(mcParams.Name{indexI},'.',''),inputListRun.Properties.VariableNames);
    mcParams.Lower(indexI) = min(table2array(bestInputs(:,tempIndex)));
    mcParams.Upper(indexI) = max(table2array(bestInputs(:,tempIndex)));
end

save updatedMCParams mcParams;



end

function rho_2 = weightedPearson(X, Y, w)

mX = sum(X .* w) / sum(w);
mY = sum(Y .* w) / sum(w);

covXY = sum (w .* (X - mX) .* (Y - mY)) / sum(w);
covXX = sum (w .* (X - mX) .* (X - mX)) / sum(w);
covYY = sum (w .* (Y - mY) .* (Y - mY)) / sum(w);

rho_w  = covXY / sqrt(covXX * covYY);
rho_2 = rho_w * rho_w;

end

function plotMigrations(matrix, r2, metricTitle)

load midasLocations;

figure;
imagesc(matrix);
set(gca,'YTick',1:64, 'XTick',1:64, 'YTickLabel',midasLocations.source_ADMIN_NAME, 'XTickLabel',midasLocations.source_ADMIN_NAME);
xtickangle(90);
colorbar;
title([metricTitle ' - Interdistrict moves (n = ' num2str(sum(sum(matrix))) '; Weighted r^2 = ' num2str(r2) ')']);
grid on;
colormap hot;
set(gca,'GridColor','white','FontSize',12);
temp = ylabel('ORIGIN','FontSize',16,'Position',[-5 30]);
xlabel('DESTINATION','FontSize',16);
%set(temp,'Position', [-.1 .5 0]);
set(gcf,'Position',[100 100 600 500]);

end