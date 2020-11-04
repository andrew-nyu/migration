function buildABCCalibrationExercise()

addpath('./ABC_Calibration_MIDAS_Code');

saveDirectory = './Calibration_Outputs/';
experimentPreDirectory = './MIDAS_Outputs_for_Calibration/' ;

experimentDirectory = [experimentPreDirectory 'Calibration_Exercise_' num2str(length(dir([experimentPreDirectory 'Calibration_Exercise_*']))) '/'];

if ~exist(saveDirectory, 'dir')
    mkdir(saveDirectory);
end
if ~exist(experimentPreDirectory, 'dir')
    mkdir(experimentPreDirectory);
end
if ~exist(experimentDirectory, 'dir')
    mkdir(experimentDirectory);
end

% first initialize the mcParams that are going to be calibrated and store 

mcParams = table([],[],[],[],'VariableNames',{'Name','Lower','Upper','RoundYN'});

    mcParams = [mcParams; {'modelParameters.spinupTime', 8, 20, 1}];
    mcParams = [mcParams; {'modelParameters.numAgents', 3000, 6000, 1}];
    mcParams = [mcParams; {'modelParameters.utility_k', 1, 5, 0}];
    mcParams = [mcParams; {'modelParameters.utility_m', 1, 2, 0}];
    mcParams = [mcParams; {'modelParameters.utility_noise', 0, 0.1, 0}];
    mcParams = [mcParams; {'modelParameters.utility_iReturn', 0, 0.2, 0}];
    mcParams = [mcParams; {'modelParameters.utility_iDiscount', 0, 0.1, 0}];
    mcParams = [mcParams; {'modelParameters.utility_iYears', 10, 20, 1}];
    mcParams = [mcParams; {'modelParameters.accessCost1', 1, 1000, 0}];
    mcParams = [mcParams; {'modelParameters.accessCost2', 1, 1000, 0}];
    mcParams = [mcParams; {'modelParameters.accessCost3', 1, 1000, 0}];
    mcParams = [mcParams; {'modelParameters.accessCost4', 1, 1000, 0}];
    mcParams = [mcParams; {'modelParameters.creditMultiplier', 0, 2, 0}];
    mcParams = [mcParams; {'modelParameters.remitRate', 0, 20, 0}];
    mcParams = [mcParams; {'agentParameters.coeffPoverty', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffFood', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffHealth', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffEducation', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffGender', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffWater', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffEnergy', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffEconomy', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffInnovation', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffInequality', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffCities', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffConsumption', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffClimate', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffOcean', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffLand', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffPeace', 0, 100, 0}];
    mcParams = [mcParams; {'agentParameters.coeffCooperation', 0, 100, 0}];
    mcParams = [mcParams; {'mapParameters.movingCostPerMile', 0, 5000, 0}];
    mcParams = [mcParams; {'mapParameters.minDistForCost', 0, 50, 0}];
    mcParams = [mcParams; {'mapParameters.maxDistForCost', 0, 5000, 0}];
    mcParams = [mcParams; {'networkParameters.networkDistanceSD', 5, 15, 1}];
    mcParams = [mcParams; {'networkParameters.connectionsMean', 1, 5, 1}];
    mcParams = [mcParams; {'networkParameters.connectionsSD', 1, 3, 1}];
    mcParams = [mcParams; {'networkParameters.weightLocation', 5, 15, 0}];
    mcParams = [mcParams; {'networkParameters.weightNetworkLink', 5, 15, 0}];
    mcParams = [mcParams; {'networkParameters.weightSameLayer', 3, 10, 0}];
    mcParams = [mcParams; {'networkParameters.distancePolynomial', 0.0001, 0.0003, 0}];
    mcParams = [mcParams; {'networkParameters.decayPerStep', 0.001, 0.01, 0}];
    mcParams = [mcParams; {'networkParameters.interactBump', 0.005, 0.03, 0}];
    mcParams = [mcParams; {'networkParameters.shareBump', 0.0005, 0.005, 0}];
    mcParams = [mcParams; {'agentParameters.incomeShareFractionMean', 0.2, 0.6, 0}];
    mcParams = [mcParams; {'agentParameters.incomeShareFractionSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.shareCostThresholdMean', 0.2, 0.6, 0}];
    mcParams = [mcParams; {'agentParameters.shareCostThresholdSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.interactMean', 0.2, 0.6, 0}];
    mcParams = [mcParams; {'agentParameters.interactSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.meetNewMean', 0.2, 0.6, 0}];
    mcParams = [mcParams; {'agentParameters.meetNewSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.probAddFitElementMean', 0.2, 0.6, 0}];
    mcParams = [mcParams; {'agentParameters.probAddFitElementSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.randomLearnMean', 0.2, 0.6, 0}];
    mcParams = [mcParams; {'agentParameters.randomLearnSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.randomLearnCountMean', 1, 3, 1}];
    mcParams = [mcParams; {'agentParameters.randomLearnCountSD', 0, 2, 1}];
    mcParams = [mcParams; {'agentParameters.chooseMean', 0.4, 0.8, 0}];
    mcParams = [mcParams; {'agentParameters.chooseSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.knowledgeShareFracMean', 0.05, 0.4, 0}];
    mcParams = [mcParams; {'agentParameters.knowledgeShareFracSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.bestLocationMean', 1, 3, 1}];
    mcParams = [mcParams; {'agentParameters.bestLocationSD', 0, 2, 1}];
    mcParams = [mcParams; {'agentParameters.bestPortfolioMean', 1, 3, 1}];
    mcParams = [mcParams; {'agentParameters.bestPortfolioSD', 0, 2, 1}];
    mcParams = [mcParams; {'agentParameters.randomLocationMean', 1, 3, 1}];
    mcParams = [mcParams; {'agentParameters.randomLocationSD', 0, 2, 1}];
    mcParams = [mcParams; {'agentParameters.randomPortfolioMean', 1, 3, 1}];
    mcParams = [mcParams; {'agentParameters.randomPortfolioSD', 0, 2, 1}];
    mcParams = [mcParams; {'agentParameters.numPeriodsEvaluateMean', 6, 24, 1}];
    mcParams = [mcParams; {'agentParameters.numPeriodsEvaluateSD', 0, 6, 1}];
    mcParams = [mcParams; {'agentParameters.numPeriodsMemoryMean', 6, 24, 1}];
    mcParams = [mcParams; {'agentParameters.numPeriodsMemorySD', 0, 6, 1}];
    mcParams = [mcParams; {'agentParameters.discountRateMean', 0.02, 0.1, 0}];
    mcParams = [mcParams; {'agentParameters.discountRateSD', 0, 0.02, 0}];
    mcParams = [mcParams; {'agentParameters.rValueMean', 0.75, 1.5, 0}];
    mcParams = [mcParams; {'agentParameters.rValueSD', 0.1, 0.4 , 0}];
    mcParams = [mcParams; {'agentParameters.bListSD', 0, 0.5, 0}];
    mcParams = [mcParams; {'agentParameters.prospectLossMean', 1, 2, 0}];
    mcParams = [mcParams; {'agentParameters.prospectLossSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.informedExpectedProbJoinLayerMean', 0.8, 1,0}];
    mcParams = [mcParams; {'agentParameters.informedExpectedProbJoinLayerSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.uninformedMaxExpectedProbJoinLayerMean', 0, 0.4, 0}];
    mcParams = [mcParams; {'agentParameters.uninformedMaxExpectedProbJoinLayerSD', 0, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.expectationDecayMean', 0.05, 0.2, 0}];
    mcParams = [mcParams; {'agentParameters.expectationDecaySD', 0, 0.2, 0}];

% diego: changed the save directory for clarity
save ./Calibration_Outputs/updatedMCParams mcParams;

end