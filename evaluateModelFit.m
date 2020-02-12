function evaluateModelFit()

clear all;
close all;

quantileMarker = 0.02;

series = 'MC_Run_'; % change series name in function of which model outputs you want to use to calibrate

saveDirectory = './Outputs/';
loadDirectory = './February11/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  empirical data import
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

migrationData=csvread("A&R1015_264countries_matrixID.csv",1,1);
countryData=csvread("all_countries4.csv");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% metric for the evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% assing nans to rows and columns of countries without data
for indexJ = 1:length(countryData)
       if countryData(indexJ,2)==0
           migrationData(indexJ,:)=NaN;
           migrationData(:,indexJ)=NaN;
       end    
end
% removing nans from raftery data
migrationData = migrationData(:,~all(isnan(migrationData)));
migrationData = migrationData(~all(isnan(migrationData),2),:);

%one simple metric is the relative # of migrations per source-destination
%pair
fracMigsData = migrationData / sum(sum(migrationData));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% import model outcomes and calculate wieghted pearson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileList = dir([loadDirectory series '*']);

for indexI = 1:length(fileList)

   currentRun = load([loadDirectory fileList(indexI).name]); 
   migrationMatrix=currentRun.output.migrationMatrix;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % excluding countries absent from raftery
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % assing nans to rows and columns of countries without data
   for indexJ = 1:length(countryData)
       if countryData(indexJ,2)==0
           migrationMatrix(indexJ,:)=NaN;
           migrationMatrix(:,indexJ)=NaN;
       end    
   end
   
   %removing nans from model output
   migrationMatrix = migrationMatrix(:,~all(isnan(migrationMatrix)));
   migrationMatrix = migrationMatrix(~all(isnan(migrationMatrix),2),:);
   
   
   %one simple metric is the relative # of migrations per source-destination
   %pair
   fracMigsRun = migrationMatrix / sum(sum(migrationMatrix));
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % all done! now the test
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   fracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), ones(numel(fracMigsRun),1));

   currentOutputRun = table(fracMigs_r2,indexI, ...
       'VariableNames',{'fracMigs_r2','index'});
   
   outputListRun(indexI,:) = currentOutputRun ;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save evaluationOutputs inputListRun outputListRun fileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
minR2 = quantile(outputListRun.fracMigs_r2,[1 - quantileMarker]);
bestInputs = outputListRun(outputListRun.fracMigs_r2>=minR2,:);
for indexI = 1:length(bestInputs.index)
    filenames{indexI}=fileList(bestInputs.index(indexI)).name;
end    

for indexI = 1:length(filenames)
    fname=filenames(indexI);
    currentRun = load([loadDirectory fname{1}]);
    successParams = currentRun.input;
    successList{indexI} = successParams;
    
end 

fprintf(['Saving Good Parameters List.\n']);
save([saveDirectory 'experiment_' date '_calibration'], 'successList');

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
