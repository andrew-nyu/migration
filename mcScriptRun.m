outputList = {};

%number of runs
modelRuns = 100;

%define the levels and parameters you will explore, as below
parameterNames = {  'modelParameters.numAgents'; ...
    'networkParameters.networkDistanceSD'};
parameterLimits = { [1000 5000]; ...
    [3 15]};
roundValYN = [1 0];

%make the full factorial design

for indexI = 1:modelRuns
    experiment = dataset([],[],'VarNames',{'parameterNames','parameterValues'});
    for indexJ = 1:(size(parameterNames))
        tempName = parameterNames{indexJ};
        tempMin = parameterLimits{indexJ}(1);
        tempMax = parameterLimits{indexJ}(2);
        tempValue = tempMin + (tempMax-tempMin) * rand();
        if(roundValYN(indexJ))
            tempValue = round(tempValue);
        end
        newRun = dataset({tempName}, tempValue, 'VarNames',{'parameterNames','parameterValues'});
        experiment = vertcat(experiment, newRun);
    end
    experimentList{indexI} = experiment;
end

for indexI = 1:length(experimentList)
%for indexI = 1:length(experimentList)
    outputList{indexI} = runMigrationModel(experimentList{indexI}, ['Run ' num2str(indexI)]);
end

save experiment_August_25 experimentList outputList fullDesign parameterNames parameterLimits roundValYN