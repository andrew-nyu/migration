outputList = {};

%number of runs
modelRuns = 100;

%define the levels and parameters you will explore, as below
mcParams = table([],[],[],[],'VariableNames',{'Name','Lower','Upper','RoundYN'});

mcParams = [mcParams; {'modelParameters.numAgents', 1000, 5000, 1}];

mcParams = [mcParams; {'modelParameters.incomeInterval', 1, 4, 1}];
mcParams = [mcParams; {'networkParameters.networkDistanceSD', 5, 15, 1}];
mcParams = [mcParams; {'networkParameters.connectionsMean', 1, 5, 1}];
mcParams = [mcParams; {'networkParameters.connectionsSD', 1, 3, 1}];
mcParams = [mcParams; {'agentParameters.incomeShareFractionMean', 0.2, 0.6, 0}];
mcParams = [mcParams; {'agentParameters.incomeShareFractionSD', 0, 0.2, 0}];
mcParams = [mcParams; {'agentParameters.shareCostThresholdMean', 0.2, 0.4, 0}];
mcParams = [mcParams; {'agentParameters.shareCostThresholdSD', 0, 0.2, 0}];
mcParams = [mcParams; {'agentParameters.interactMean', 0.2, 0.6, 0}];
mcParams = [mcParams; {'agentParameters.interactSD', 0, 0.2, 0}];
mcParams = [mcParams; {'agentParameters.randomLearnMean', 0, 1, 0}];
mcParams = [mcParams; {'agentParameters.randomLearnSD', 0, 0.2, 0}];
mcParams = [mcParams; {'agentParameters.randomLearnCountMean', 1, 3, 1}];
mcParams = [mcParams; {'agentParameters.randomLearnCountSD', 0, 2, 1}];
mcParams = [mcParams; {'agentParameters.chooseMean', 0.2, 0.6, 0}];
mcParams = [mcParams; {'agentParameters.chooseSD', 0, 0.2, 0}];
mcParams = [mcParams; {'agentParameters.knowledgeShareFracMean', 0.05, 0.2, 0}];
mcParams = [mcParams; {'agentParameters.knowledgeShareFracSD', 0, 0.05, 0}];
mcParams = [mcParams; {'agentParameters.bestLocationMean', 1, 3, 1}];
mcParams = [mcParams; {'agentParameters.bestLocationSD', 0, 1, 1}];
mcParams = [mcParams; {'agentParameters.bestPortfolioMean', 1, 3, 1}];
mcParams = [mcParams; {'agentParameters.bestPortfolioSD', 0, 1, 1}];
mcParams = [mcParams; {'agentParameters.randomLocationMean', 1, 3, 1}];
mcParams = [mcParams; {'agentParameters.randomLocationSD', 0, 1, 1}];
mcParams = [mcParams; {'agentParameters.randomPortfolioMean', 1, 3, 1}];
mcParams = [mcParams; {'agentParameters.randomPortfolioSD', 0, 1, 1}];
mcParams = [mcParams; {'agentParameters.numPeriodsEvaluateMean', 12, 24, 1}];
mcParams = [mcParams; {'agentParameters.numPeriodsEvaluateSD', 0, 6, 1}];
mcParams = [mcParams; {'agentParameters.numPeriodsMemoryMean', 12, 24, 1}];
mcParams = [mcParams; {'agentParameters.numPeriodsMemorySD', 0, 6, 1}];
mcParams = [mcParams; {'agentParameters.discountRateMean', 0.02, 0.1, 0}];
mcParams = [mcParams; {'agentParameters.discountRateSD', 0, 0.02, 0}];
mcParams = [mcParams; {'agentParameters.rValueMean', 0.5, 1, 0}];
mcParams = [mcParams; {'agentParameters.rValueSD', 0, 0.2, 0}];

%make the full factorial design

for indexI = 1:modelRuns
    experiment = table([],[],'VariableNames',{'parameterNames','parameterValues'});
    for indexJ = 1:(height(mcParams))
        tempName = mcParams.Name{indexJ};
        tempMin = mcParams.Lower(indexJ);
        tempMax = mcParams.Upper(indexJ);
        tempValue = tempMin + (tempMax-tempMin) * rand();
        if(mcParams.RoundYN(indexJ))
            tempValue = round(tempValue);
        end
        experiment = [experiment;{tempName, tempValue}];
    end
    experimentList{indexI} = experiment;
end

for indexI = 1:length(experimentList)
%for indexI = 1:length(experimentList)
    outputList{indexI} = runMigrationModel(experimentList{indexI}, ['Run ' num2str(indexI)]);
end

save experiment_August_25 experimentList outputList fullDesign parameterNames parameterLimits roundValYN