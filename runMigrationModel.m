function [outputs] = runMigrationModel(inputs, runName)
%runMigrationModel.m main time loop of migration model


%clear all;
close all;

tic;

outputs = [];
[agentList, modelParameters, networkParameters, mapParameters, utilityVariables, mapVariables] = setupLandscape(inputs);

numLocations = size(mapVariables.locations,1);
numLayers = size(utilityVariables.utilityLayerFunctions,1);

sizeArray = size(utilityVariables.utilityHistory);

%create any other outcome variables of interest
countAgentsPerLayer = zeros(numLocations, numLayers, modelParameters.timeSteps);
averageWealth = zeros(modelParameters.timeSteps ,1);
migrations = zeros(modelParameters.timeSteps,1);

for indexT = 1:modelParameters.timeSteps
   
    currentRandOrder = randperm(modelParameters.numAgents);
    for indexA = 1:modelParameters.numAgents
        
        currentAgent = agentList(currentRandOrder(indexA));
        
        %draw number to see if agent has social interaction
        if(rand() < currentAgent.pInteract)
            if(~isempty(currentAgent.network))
                %choose an agent in social network and exchange
                
                %have to name currentAgent and partner as outputs of the
                %function, otherwise MATLAB simply creates a copy of them
                %inside the function to do writing, and doesn't write to
                %the original
                partner = currentAgent.network(randperm(length(currentAgent.network),1));

                [currentAgent, partner] = interact(currentAgent, partner);
                currentAgent.knowsIncomeLocation = any(currentAgent.incomeLayersHistory,3);
                partner.knowsIncomeLocation = any(partner.incomeLayersHistory,3);

            end
        end
        
        %draw number to see if agent learns anything randomly new about
        %income in the world around it
        if(rand() < currentAgent.pRandomLearn)
            currentAgent.incomeLayersHistory(randperm(prod([sizeArray(1:2) indexT]),currentAgent.countRandomLearn)) = true;
        end
        

        %draw number to see if agent updates preferences on where to
        %be/what to do
        if(rand() < currentAgent.pChoose && indexT > modelParameters.spinupTime)
            [currentAgent, moved] = choosePortfolio(currentAgent, utilityVariables, indexT, modelParameters, mapParameters, mapVariables);
            migrations(indexT) = migrations(indexT) + moved;
        end
       
        
    end %for indexA = 1:modelParameters.numAgents
    
    if (mod(indexT, modelParameters.incomeInterval) == 0)
        
        %construct the current counts of the number of agents occupying
        %each layer
        agentCityIndex = [agentList(:).matrixLocation]';
        for indexA = 1:modelParameters.numAgents
            currentPortfolio = agentList(indexA).currentPortfolio;
            countAgentsPerLayer(agentCityIndex(indexA), currentPortfolio, indexT) = countAgentsPerLayer(agentCityIndex(indexA), currentPortfolio, indexT) + 1;
        end
        
        %add income layer to history
        %income functions are of the form f(x, y, t, n, varargin)
        %be sure that whatever your income functions are, the cellfun input
        %matches appropriately
        for indexL = 1:numLayers
            utilityVariables.utilityHistory(:,indexL, indexT) = arrayfun(utilityVariables.utilityLayerFunctions{indexL}, ...
                mapVariables.locations.locationX, ...
                mapVariables.locations.locationY, ...
                ones(numLocations,1)*indexT, ...
                countAgentsPerLayer(:,indexL), ...
                utilityVariables.utilityBaseLayers(:,indexL,indexT));
        end
        
        %make payments and transfers as appropriate to all agents, and
        %update knowledge
        for indexA = 1:modelParameters.numAgents
            currentAgent = agentList(indexA);
            
            %find out how much the current agent made, from each layer, and
            %update their knowledge
            newIncome = sum(utilityVariables.utilityHistory(currentAgent.matrixLocation,currentAgent.currentPortfolio, indexT));
            
            %add in any income that has been shared in to the agent, to
            %include in sharing-out decision-making
            newIncome = newIncome + currentAgent.currentSharedIn;
            currentAgent.currentSharedIn = 0;
            currentAgent.personalIncomeHistory(indexT) = newIncome;
            
            currentAgent.incomeLayersHistory(currentAgent.matrixLocation,currentAgent.currentPortfolio,indexT) = true;
            currentAgent.knowsIncomeLocation(currentAgent.matrixLocation, currentAgent.currentPortfolio) = true;
            
            
            %estimate the gross intention of sharing out across network
            amountToShare = newIncome * currentAgent.incomeShareFraction;
            networkStrengths = mapVariables.network(currentAgent.id, [currentAgent.network(:).id]);
            potentialAmounts = (networkStrengths ./ sum(networkStrengths)) * amountToShare;
            
            %calculate costs associated with those shares
            remittanceFee = mapVariables.remittanceFee(currentAgent.matrixLocation, [currentAgent.network(:).matrixLocation]);
            remittanceRate = mapVariables.remittanceRate(currentAgent.matrixLocation, [currentAgent.network(:).matrixLocation]);
            remittanceCost = remittanceFee + remittanceRate / 100 .* potentialAmounts;
            
            %discard any potential transfers that exceed agent's threshold
            %for costs (i.e., agent stops making transfers if the
            %transaction costs are too much of the overall cost)
            feasibleTransfers = remittanceCost ./ potentialAmounts > currentAgent.shareCostThreshold;
            actualAmounts = (potentialAmounts - remittanceCost) .* feasibleTransfers;
            
            %share across network and keep the rest
            for indexN = 1:size(currentAgent.network,2)
                    currentConnection = currentAgent.network(indexN);
                    currentConnection.lastIntendedShareIn(currentAgent.myIndexInNetwork(indexN)) = potentialAmounts(indexN);
                if(actualAmounts(indexN) > 0)
                    
                    %income shared in is held separate until that agent
                    %comes around to their own income loop
                    currentConnection.currentSharedIn = currentConnection.currentSharedIn + actualAmounts(indexN);
                end
            end
            currentAgent.wealth = currentAgent.wealth + newIncome - sum(actualAmounts);
        end
    end %if (mod(indexT, modelParameters.incomeInterval) == 0)
    
    if (modelParameters.visualizeYN & mod(indexT, modelParameters.visualizeInterval) == 0)
        
        %visualize the map
        [mapHandle] = visualizeMap(agentList, mapVariables, mapParameters);
        drawnow();
        fprintf([runName ' - Map updated.\n']);
        if(modelParameters.saveImg)
           print('-dpng','-painters','-r300', [modelParameters.shortName num2str(indexT) '.png']); 
           fprintf([runName ' - Map saved.\n']);
                   
        end

    end
    
    averageWealth(indexT) = mean([agentList(:).wealth]);
    
    fprintf([runName ' - Time step ' num2str(indexT) ' of ' num2str(modelParameters.timeSteps) ' - ' num2str(migrations(indexT)) ' migrations.\n']);

end %for indexT = 1:modelParameters.timeSteps

%prepare outputs
outputs.averageWealth = averageWealth;
outputs.countAgentsPerLayer = countAgentsPerLayer;
outputs.migrations = migrations;

toc;
end

