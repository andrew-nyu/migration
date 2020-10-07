function [minR2, successList] = modelFit(experimentDirectory,fracMigsData)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% evaluation of the model fit with a weighted R2. The function saves the
%% well fitted parameter values in a  .mat file that contains the minR2 
%% on its name. the function returns the minR2 so that it can be evaluated
%% whether ABC continues or not.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;

aggregate=1;
quantileMarker = 0.01;

countryData=csvread("countriesbyregion.csv");
if aggregate==1
    regionMembership=countryData(:,3);
    regionMembership=regionMembership(regionMembership~=0);
end    

series = 'MC_Run_'; % change series name in function of which model outputs you want to use to calibrate
%saveDirectory = './Outputs/';
loadDirectory = experimentDirectory;

% importing outcome of simulations from experimentDirectory. The files
% concerned are 'MC_Run_*'
fileList = dir([experimentDirectory series '*']);

% go over all the experiment outputs
for indexI = 1:length(fileList)

   % load indexI run and get the associated migration matrix     
   currentRun = load([loadDirectory fileList(indexI).name]); 
   migrationMatrix=currentRun.output.migrationMatrix;
   
   % excluding countries which are not present in Raftery's data. this is
   % done by assigning nans.
   for indexJ = 1:length(countryData)
       if countryData(indexJ,2)==0
           migrationMatrix(indexJ,:)=NaN;
           migrationMatrix(:,indexJ)=NaN;
       end    
   end
   
   %removing nans from model output
   migrationMatrix = migrationMatrix(:,~all(isnan(migrationMatrix)));
   migrationMatrix = migrationMatrix(~all(isnan(migrationMatrix),2),:);
   
   % aggregate countries by region
   if aggregate==1
       migrationMatrix=aggregateByRegion(migrationMatrix,regionMembership);
   end    
   
   % this is the metric used to compare
   fracMigsRun = migrationMatrix / sum(sum(migrationMatrix));
   
   
   % this is the test using weighted R2
   fracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), ones(numel(fracMigsRun),1));

   % now we save the r2 and the run index to after identify the best runs
   currentOutputRun = table(fracMigs_r2,indexI, ...
       'VariableNames',{'fracMigs_r2','index'});
   
   outputListRun(indexI,:) = currentOutputRun ;
    
end
% the loop over all the experiment runs is done. now we must select the
% best runs according to our quantile criteria. We are currently 
% selecting the top quantileMarker*100 percent

% calculating the minimum acceptable r2 given our quantile marker 
minR2 = quantile(outputListRun.fracMigs_r2,[1 - quantileMarker]);
% selecting only the runs whose r2 is in the selected range
bestInputs = outputListRun(outputListRun.fracMigs_r2>=minR2,:);

% storing the filenames of the best runs
for indexI = 1:length(bestInputs.index)
    filenames{indexI}=fileList(bestInputs.index(indexI)).name;
end

for indexI = 1:length(filenames)
    fname=filenames(indexI);
    currentRun = load([loadDirectory fname{1}]);
    successParams = currentRun.input;
    successList{indexI} = successParams;
    successList{indexI} = successParams;
end


%fprintf(['Saving Good Parameters List.\n']);
%save([saveDirectory 'experiment_' date '_calibration_R2_' minR2], 'successList');

end


