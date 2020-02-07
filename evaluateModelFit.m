function evaluateModelFit()

clear all;
close all;

quantileMarker = 0.01;

series = 'MC_Run_'; % change series name in function of which model outputs you want to use to calibrate

saveDirectory = './Outputs/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  empirical data import
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

migrationData=csvread("raftery_test_prueba.csv");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% metric for the evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%one simple metric is the relative # of migrations per source-destination
%pair
fracMigsData = migrationData / sum(sum(migrationData));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% import model outcomes and calculate wieghted pearson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileList = dir([saveDirectory series '*'])

for indexI = 1:length(fileList)

   currentRun = load([saveDirectory fileList(indexI).name]); 
   migrationMatrix=currentRun.output.migrationMatrix;
    
   fracMigsRun = migrationMatrix / sum(sum(migrationMatrix));
    
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
    currentRun = load([saveDirectory fname{1}]);
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
