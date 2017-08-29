outputList = {};

%define the levels and parameters you will explore, as below
repeats = 5;
parameterNames = {  'modelParameters.numAgents'; ...
    'networkParameters.networkDistanceSD'};
parameterValues = { [100 500 1000]; ...
    [3 7 13]};
parameterLevels = [3 3 repeats];

%make the full factorial design
fullDesign = fullfact(parameterLevels);
experimentList = {};

for indexI = 1:size(fullDesign,1)
    experiment = dataset([],[],'VarNames',{'parameterNames','parameterValues'});
    for indexJ = 1:(size(fullDesign,2)-1)
        tempName = parameterNames{indexJ};
        tempValue = parameterValues{indexJ}(fullDesign(indexI,indexJ));
        newRun = dataset({tempName}, tempValue, 'VarNames',{'parameterNames','parameterValues'});
        experiment = vertcat(experiment, newRun);
    end
    experimentList{indexI} = experiment;
end

parfor indexI = 1:length(experimentList)
%for indexI = 1:length(experimentList)
    outputList{indexI} = runMigrationModel(experimentList{indexI}, ['Run ' num2str(indexI)]);
end

save experiment_August_25 experimentList outputList fullDesign parameterNames parameterValues parameterLevels