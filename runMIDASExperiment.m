function runMIDASExperiment()

clear functions
clear classes

addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');

rng('shuffle');

outputList = {};

series = 'MC_Run_';
saveDirectory = './runsABC/';

%number of runs
modelRuns = 1000;

try mcParams=load('updatedMCParams.mat');
catch
    
    %define the levels and parameters you will explore, as below
    mcParams = table([],[],[],[],'VariableNames',{'Name','Lower','Upper','RoundYN'});
    
%     mcParams = [mcParams; {'modelParameters.spinupTime', 8, 20, 1}];
%     mcParams = [mcParams; {'modelParameters.numAgents', 3000, 6000, 1}];
%     mcParams = [mcParams; {'modelParameters.utility_k', 1, 5, 0}];
%     mcParams = [mcParams; {'modelParameters.utility_m', 1, 2, 0}];
%     mcParams = [mcParams; {'modelParameters.utility_noise', 0, 0.1, 0}];
%     mcParams = [mcParams; {'modelParameters.utility_iReturn', 0, 0.2, 0}];
%     mcParams = [mcParams; {'modelParameters.utility_iDiscount', 0, 0.1, 0}];
%     mcParams = [mcParams; {'modelParameters.utility_iYears', 10, 20, 1}];
%     mcParams = [mcParams; {'modelParameters.creditMultiplier', 0, 2, 0}];
%     mcParams = [mcParams; {'modelParameters.remitRate', 0, 20, 0}];
%    mcParams = [mcParams; {'mapParameters.movingCostPerMile', 0, 5000, 0}];
%     mcParams = [mcParams; {'mapParameters.minDistForCost', 0, 50, 0}];
%     mcParams = [mcParams; {'mapParameters.maxDistForCost', 0, 5000, 0}];
%     mcParams = [mcParams; {'networkParameters.networkDistanceSD', 5, 15, 1}];
%     mcParams = [mcParams; {'networkParameters.connectionsMean', 1, 5, 1}];
%     mcParams = [mcParams; {'networkParameters.connectionsSD', 1, 3, 1}];
%     mcParams = [mcParams; {'networkParameters.weightLocation', 5, 15, 0}];
%     mcParams = [mcParams; {'networkParameters.weightNetworkLink', 5, 15, 0}];
%     mcParams = [mcParams; {'networkParameters.weightSameLayer', 3, 10, 0}];
%     mcParams = [mcParams; {'networkParameters.distancePolynomial', 0.0001, 0.0003, 0}];
%     mcParams = [mcParams; {'networkParameters.decayPerStep', 0.001, 0.01, 0}];
%     mcParams = [mcParams; {'networkParameters.interactBump', 0.005, 0.03, 0}];
%     mcParams = [mcParams; {'networkParameters.shareBump', 0.0005, 0.005, 0}];
%     mcParams = [mcParams; {'agentParameters.incomeShareFractionMean', 0.2, 0.6, 0}];
%     mcParams = [mcParams; {'agentParameters.incomeShareFractionSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.shareCostThresholdMean', 0.2, 0.6, 0}];
%     mcParams = [mcParams; {'agentParameters.shareCostThresholdSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.interactMean', 0.2, 0.6, 0}];
%     mcParams = [mcParams; {'agentParameters.interactSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.meetNewMean', 0.2, 0.6, 0}];
%     mcParams = [mcParams; {'agentParameters.meetNewSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.probAddFitElementMean', 0.2, 0.6, 0}];
%     mcParams = [mcParams; {'agentParameters.probAddFitElementSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.randomLearnMean', 0.2, 0.6, 0}];
%     mcParams = [mcParams; {'agentParameters.randomLearnSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.randomLearnCountMean', 1, 3, 1}];
%     mcParams = [mcParams; {'agentParameters.randomLearnCountSD', 0, 2, 1}];
%     mcParams = [mcParams; {'agentParameters.chooseMean', 0.4, 0.8, 0}];
%     mcParams = [mcParams; {'agentParameters.chooseSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.knowledgeShareFracMean', 0.05, 0.4, 0}];
%     mcParams = [mcParams; {'agentParameters.knowledgeShareFracSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.bestLocationMean', 1, 3, 1}];
%     mcParams = [mcParams; {'agentParameters.bestLocationSD', 0, 2, 1}];
%     mcParams = [mcParams; {'agentParameters.bestPortfolioMean', 1, 3, 1}];
%     mcParams = [mcParams; {'agentParameters.bestPortfolioSD', 0, 2, 1}];
%     mcParams = [mcParams; {'agentParameters.randomLocationMean', 1, 3, 1}];
%     mcParams = [mcParams; {'agentParameters.randomLocationSD', 0, 2, 1}];
%     mcParams = [mcParams; {'agentParameters.randomPortfolioMean', 1, 3, 1}];
%     mcParams = [mcParams; {'agentParameters.randomPortfolioSD', 0, 2, 1}];
%     mcParams = [mcParams; {'agentParameters.numPeriodsEvaluateMean', 6, 24, 1}];
%     mcParams = [mcParams; {'agentParameters.numPeriodsEvaluateSD', 0, 6, 1}];
%     mcParams = [mcParams; {'agentParameters.numPeriodsMemoryMean', 6, 24, 1}];
%     mcParams = [mcParams; {'agentParameters.numPeriodsMemorySD', 0, 6, 1}];
%     mcParams = [mcParams; {'agentParameters.discountRateMean', 0.02, 0.1, 0}];
%     mcParams = [mcParams; {'agentParameters.discountRateSD', 0, 0.02, 0}];
%     mcParams = [mcParams; {'agentParameters.rValueMean', 0.75, 1.5, 0}];
%     mcParams = [mcParams; {'agentParameters.rValueSD', 0.1, 0.4 , 0}];
%     mcParams = [mcParams; {'agentParameters.bListMean', 0.5, 1, 0}];
%     mcParams = [mcParams; {'agentParameters.bListSD', 0, 0.4, 0}];
%     mcParams = [mcParams; {'agentParameters.prospectLossMean', 1, 2, 0}];
%     mcParams = [mcParams; {'agentParameters.prospectLossSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.informedExpectedProbJoinLayerMean', 0.8, 1,0}];
%     mcParams = [mcParams; {'agentParameters.informedExpectedProbJoinLayerSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.uninformedMaxExpectedProbJoinLayerMean', 0, 0.4, 0}];
%     mcParams = [mcParams; {'agentParameters.uninformedMaxExpectedProbJoinLayerSD', 0, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.expectationDecayMean', 0.05, 0.2, 0}];
%     mcParams = [mcParams; {'agentParameters.expectationDecaySD', 0, 0.2, 0}];
end
%make the full design

fprintf(['Building Experiment List.\n']);
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

fprintf(['Saving Experiment List.\n']);
save([saveDirectory 'experiment_' date '_input_summary'], 'experimentList', 'mcParams');

runList = zeros(length(experimentList),1);
%run the model
for indexI = 1:length(experimentList)
%for indexI = 1:length(experimentList)
    if(runList(indexI) == 0)
        input = experimentList{indexI};
        
        %this next line runs MIDAS using the current experimental
        %parameters
        output = midasMainLoop(input, ['Experiment Run ' num2str(indexI)]);
        
        
        functionVersions = inmem('-completenames');
        functionVersions = functionVersions(strmatch(pwd,functionVersions));
        output.codeUsed = functionVersions;
        currentFile = [series num2str(length(dir([series '*']))) '_' datestr(now) '.mat'];
        currentFile = [saveDirectory currentFile];
        
        %make the filename compatible across Mac/PC
        currentFile = strrep(currentFile,':','-');
        currentFile = strrep(currentFile,' ','_');

        saveToFile(input, output, currentFile);
        runList(indexI) = 1;
    end
end

end

function saveToFile(input, output, filename);
    save(filename,'input', 'output');
end