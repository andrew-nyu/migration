function runABCCalibration()

addpath('./ABC_Calibration_MIDAS_Code');

saveDirectory = './' ; % current location
saveDirectory2 = './Calibration_Results/';
experimentDirectory = './RunsABC_Temp/' ;

% first initialize the updatedMCparams that are going to be calibrated and store 
% them in updatedupdatedMCparams so they can be loaded by by runMidasExperiment

updatedMCparams = table([],[],[],[],'VariableNames',{'Name','Lower','Upper','RoundYN'});

%     updatedMCparams = [updatedMCparams; {'modelParameters.spinupTime', 8, 20, 1}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.numAgents', 3000, 6000, 1}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.utility_k', 1, 5, 0}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.utility_m', 1, 2, 0}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.utility_noise', 0, 0.1, 0}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.utility_iReturn', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.utility_iDiscount', 0, 0.1, 0}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.utility_iYears', 10, 20, 1}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.creditMultiplier', 0, 2, 0}];
%     updatedMCparams = [updatedMCparams; {'modelParameters.remitRate', 0, 20, 0}];
    updatedMCparams = [updatedMCparams; {'mapParameters.movingCostPerMile', 0, 5000, 0}];
%     updatedMCparams = [updatedMCparams; {'mapParameters.minDistForCost', 0, 50, 0}];
%     updatedMCparams = [updatedMCparams; {'mapParameters.maxDistForCost', 0, 5000, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.networkDistanceSD', 5, 15, 1}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.connectionsMean', 1, 5, 1}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.connectionsSD', 1, 3, 1}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.weightLocation', 5, 15, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.weightNetworkLink', 5, 15, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.weightSameLayer', 3, 10, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.distancePolynomial', 0.0001, 0.0003, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.decayPerStep', 0.001, 0.01, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.interactBump', 0.005, 0.03, 0}];
%     updatedMCparams = [updatedMCparams; {'networkParameters.shareBump', 0.0005, 0.005, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.incomeShareFractionMean', 0.2, 0.6, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.incomeShareFractionSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.shareCostThresholdMean', 0.2, 0.6, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.shareCostThresholdSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.interactMean', 0.2, 0.6, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.interactSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.meetNewMean', 0.2, 0.6, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.meetNewSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.probAddFitElementMean', 0.2, 0.6, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.probAddFitElementSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomLearnMean', 0.2, 0.6, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomLearnSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomLearnCountMean', 1, 3, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomLearnCountSD', 0, 2, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.chooseMean', 0.4, 0.8, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.chooseSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.knowledgeShareFracMean', 0.05, 0.4, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.knowledgeShareFracSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.bestLocationMean', 1, 3, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.bestLocationSD', 0, 2, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.bestPortfolioMean', 1, 3, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.bestPortfolioSD', 0, 2, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomLocationMean', 1, 3, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomLocationSD', 0, 2, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomPortfolioMean', 1, 3, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.randomPortfolioSD', 0, 2, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.numPeriodsEvaluateMean', 6, 24, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.numPeriodsEvaluateSD', 0, 6, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.numPeriodsMemoryMean', 6, 24, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.numPeriodsMemorySD', 0, 6, 1}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.discountRateMean', 0.02, 0.1, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.discountRateSD', 0, 0.02, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.rValueMean', 0.75, 1.5, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.rValueSD', 0.1, 0.4 , 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.bListMean', 0.5, 1, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.bListSD', 0, 0.4, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.prospectLossMean', 1, 2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.prospectLossSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.informedExpectedProbJoinLayerMean', 0.8, 1,0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.informedExpectedProbJoinLayerSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.uninformedMaxExpectedProbJoinLayerMean', 0, 0.4, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.uninformedMaxExpectedProbJoinLayerSD', 0, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.expectationDecayMean', 0.05, 0.2, 0}];
%     updatedMCparams = [updatedMCparams; {'agentParameters.expectationDecaySD', 0, 0.2, 0}];

save([saveDirectory 'updatedMCParams'], 'updatedMCparams');

% import the empirical data for calibration
fracMigsData=buildMigrationData();

% set the conditions to determine success in the calibration process
R2=1000;
R2_old=0;
R2_diff=0.001;

while abs(R2-R2_old)> R2_diff
    
    R2_old=R2;    
    
    % remove data from previous calibration runs
    rmdir(experimentDirectory,'s')
    % run updated simulations
    runMidasExperiment();

    % evaluate the goodness of fit with modelFit function. The function
    % returns the minimum weighted R2 corresponding to the top one percent
    % simulations and a successList containing the name of the calibrated
    % parameters and their value 
    [R2, successList] = modelFit(experimentDirectory,fracMigsData);
    
    % get the minimum and maximum of each of the successList parameters and
    % stock them in updatedupdatedMCparams
    for indexI = 1:length(successList)
        for indexJ = 1:length(height(successList{indexI}))
            
            % get calibration parameter name and the succesful value
            paramName = successList{indexI}.parameterNames(indexJ);
            paramValue = successList{indexI}.parameterValues(indexJ);
            
            % find the row corresponding to current parameter
            index = find(strcmp(paramName,updatedupdatedMCparams.Name));
            
            % check if the value is the minimum or the maximum of all the
            % previously selected for next calibration round
            if isempty(updatedupdatedMCparams.Lower(index))
                updatedupdatedMCparams.Lower(index) = paramValue;
                updatedupdatedMCparams.Upper(index) = paramValue;
            elseif paramValue < updatedupdatedMCparams.Lower(index)
                updatedupdatedMCparams.Lower(index) = paramValue;  
            elseif paramValue > updatedupdatedMCparams.Upper(index)
                updatedupdatedMCparams.Upper(index) = paramValue;
            end    
        end    
    end
    save([saveDirectory 'updatedMCParams'], 'updatedMCparams');
    % all the selected parameter values were traversed and the minimum and
    % maximum of each parameter were saved in updatedupdatedMCparams for next
    % calibration round
    
end

% clearing the temporal directories used for calibration
rmdir(experimentDirectory,'s');
rmdir(saveDirectory,'s');
% save the calibration result, containing the best parameter distribution
save([saveDirectory2 'calibrationResult_' date ], 'updatedMCparams');
