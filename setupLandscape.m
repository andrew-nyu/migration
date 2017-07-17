function [agentList, modelParameters, networkParameters, mapParameters, utilityVariables, mapVariables] = setupLandscape()

%All model parameters go here
modelParameters.spinupTime = 12;
modelParameters.numAgents = 500;
mapParameters.sizeX = 600;
mapParameters.sizeY = 600;
modelParameters.timeSteps = 240;
modelParameters.cycleLength = 4;
modelParameters.incomeInterval = 1;
modelParameters.visualizeInterval = 12;
networkParameters.networkDistanceSD = 7;
networkParameters.connectionsMean = 2;
networkParameters.connectionsSD = 2;
mapParameters.density = 20; %pixels per degree Lat/Long, if using .shp input
mapParameters.colorSpacing = 20;
mapParameters.numDivisionMean = [2 8 9];
mapParameters.numDivisionSD = [0 2 1];
mapParameters.r1 = []; %this will be the spatial reference if we are pulling from a shape file
mapParameters.filePath = './MexUS Data/Mex_ContUS.shp';
modelParameters.saveImg = true;
modelParameters.shortName = 'MexUS_test';
agentParameters.incomeShareFractionMean = 0.4;
agentParameters.incomeShareFractionSD = 0;
agentParameters.shareCostThresholdMean = 0.3;
agentParameters.shareCostThresholdSD = 0;
agentParameters.wealthMean = 0;
agentParameters.wealthSD = 0;
agentParameters.interactMean = 0.4;
agentParameters.interactSD = 0;
agentParameters.randomLearnMean = 1;
agentParameters.randomLearnSD = 0;
agentParameters.randomLearnCountMean = 1;
agentParameters.randomLearnCountSD = 0;
agentParameters.chooseMean = 0.4;
agentParameters.chooseSD = 0;
agentParameters.knowledgeShareFracMean = 0.1;
agentParameters.knowledgeShareFracSD = 0;
agentParameters.bestLocationMean = 2;
agentParameters.bestLocationSD = 0;
agentParameters.bestPortfolioMean = 2;
agentParameters.bestPortfolioSD = 0;
agentParameters.randomLocationMean = 2;
agentParameters.randomLocationSD = 0;
agentParameters.randomPortfolioMean = 2;
agentParameters.randomPortfolioSD = 0;
agentParameters.numPeriodsEvaluateMean = 18;
agentParameters.numPeriodsEvaluateSD = 0;
agentParameters.numPeriodsMemoryMean = 18;
agentParameters.numPeriodsMemorySD = 0;
agentParameters.discountRateMean = 0.04;
agentParameters.discountRateSD = 0;
agentParameters.rValueMean = 0.8;
agentParameters.rValueSD = 0;

%create a map based on the defined administrative structure in
%mapParameters
if(isempty(mapParameters.filePath))
    [locations, map, borders] = createMap( modelParameters, mapParameters);
else
    [locations, map, borders, mapParameters] = createMapFromSHP( mapParameters);
end

%define remittance costs based on these locations
[ remittanceFee, remittanceRate ] = createRemittanceCosts(locations);

%create utility layers from the set of layers and functions defined in
%createUtilityLayers.m.  Utility is city-specific, not agent-specific, and
%history is stored in one place only, utilityHistory.  Individual agents
%have a sparse matrix of memory with 1s corresponding to utility values
%they experienced or learned.  This structure allows an arbitrarily large
%landscape with an arbitrarily large number of agents, without wasting
%memory
[utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat, utilityBaseLayers] = createUtilityLayers(locations, modelParameters.timeSteps);

%create agents and randomly allocate them to 'cities' - the term we use
%here for the lowest administrative level
numLocations = size(locations,1);
accessCodesPaid = false(size(utilityAccessCosts,1),1);
knowsIncomeLocation = sparse(size(locations,1),size(utilityAccessCosts,1));
%incomeLayersHistory = cell(size(utilityAccessCosts,1),1); %will store cell array of sparse matrices (since n-dimensional sparse are not possible)
% for indexI = 1:size(utilityAccessCosts,1)
%    incomeLayersHistory{indexI} = sparse(size(locations,1),modelParameters.timeSteps); 
% end
incomeLayersHistory = false(size(locations,1),size(utilityAccessCosts,1),modelParameters.timeSteps);

%create agents, assigning agent-specific properties as appropriate from
%input data
for indexI = 1:modelParameters.numAgents
    locationID = randi(numLocations);
    knowledgeShareFrac = min(1,max(0,agentParameters.knowledgeShareFracMean + randn() * agentParameters.knowledgeShareFracSD));
    shareCostThreshold = min(1,max(0,agentParameters.shareCostThresholdMean + randn() * agentParameters.shareCostThresholdSD));
    incomeShareFraction = min(1,max(0,agentParameters.incomeShareFractionMean + randn() * agentParameters.incomeShareFractionSD));    
    wealth = max(0,agentParameters.wealthMean + randn() * agentParameters.wealthSD);    
    numBestLocation = max(1,round(agentParameters.bestLocationMean + randn() * agentParameters.bestLocationSD));    
    numBestPortfolio = max(1,round(agentParameters.bestPortfolioMean + randn() * agentParameters.bestPortfolioSD));    
    numRandomLocation = max(1,round(agentParameters.randomLocationMean + randn() * agentParameters.randomLocationSD));    
    numRandomPortfolio = max(1,round(agentParameters.randomPortfolioMean + randn() * agentParameters.randomPortfolioSD));    
    numPeriodsEvaluate = max(1,round(agentParameters.numPeriodsEvaluateMean + randn() * agentParameters.numPeriodsEvaluateSD));    
    numPeriodsMemory = max(1,round(agentParameters.numPeriodsMemoryMean + randn() * agentParameters.numPeriodsMemorySD));    
    pInteract = min(1,max(0,agentParameters.interactMean + randn() * agentParameters.interactSD));    
    pRandomLearn = min(1,max(0,agentParameters.randomLearnMean + randn() * agentParameters.randomLearnSD));    
    countRandomLearn = min(1,max(0,agentParameters.randomLearnCountMean + randn() * agentParameters.randomLearnCountSD));    
    pChoose = min(1,max(0,agentParameters.chooseMean + randn() * agentParameters.chooseSD)); 
    rValue = max(0,agentParameters.rValueMean + randn() * agentParameters.rValueSD);
    discountRate = max(0, agentParameters.discountRateMean + randn() * agentParameters.discountRateSD);
    
   currentAgent = Agent(indexI, locations(locationID,1).cityID, accessCodesPaid, knowsIncomeLocation, incomeLayersHistory); 
   currentAgent.knowledgeShareFrac = knowledgeShareFrac;
   currentAgent.shareCostThreshold = shareCostThreshold;
   currentAgent.incomeShareFraction = incomeShareFraction;
   currentAgent.wealth = wealth;
   currentAgent.numBestLocation = numBestLocation;
   currentAgent.numBestPortfolio = numBestPortfolio;
   currentAgent.numRandomLocation = numRandomLocation;
   currentAgent.numRandomPortfolio = numRandomPortfolio;
   currentAgent.bestPortfolios = cell(size(locations,1),numBestPortfolio);
   currentAgent.bestPortfolioValues = zeros(size(locations,1),numBestPortfolio);
   currentAgent.pInteract = pInteract;
   currentAgent.pRandomLearn = pRandomLearn;
   currentAgent.countRandomLearn = countRandomLearn;
   currentAgent.pChoose = pChoose;
   currentAgent.numPeriodsEvaluate = numPeriodsEvaluate;
   currentAgent.numPeriodsMemory = numPeriodsMemory;
   currentAgent.matrixLocation = locations(locationID,:).matrixID;
   currentAgent.discountRate = discountRate;
   currentAgent.rValue = rValue;
   
   agentList(indexI) = currentAgent;
end

%Agents' 'location' is simply the city they are in, for all computational purposes,
%but for the purposes of visualization, we spread them around.  
cityMap = map(:,:,end);
for indexI = 1:size(locations,1)
   locationMapIndex = find(cityMap == locations(indexI,1).cityID); 
   locationAgents = agentList([agentList(:).location] == locations(indexI,1).cityID);
   if(isempty(locationMapIndex))
       %this particular city is either sub-pixel size or shares all pixels with other cities and lost each one
       %SO, just set visLocation to the established location of the city
       %centroid
       visLocation = locations.LocationIndex(indexI);
       [locationX, locationY] = ind2sub([mapParameters.sizeX mapParameters.sizeY],visLocation);
       for indexJ = 1:length(locationAgents)
           locationAgents(indexJ).visX = locationX + rand() - 0.5;
           locationAgents(indexJ).visY = locationY + rand() - 0.5;
       end
   else
       [locationX, locationY] = ind2sub([mapParameters.sizeX mapParameters.sizeY],locationMapIndex);
       for indexJ = 1:length(locationAgents)
           visLocation = randperm(length(locationMapIndex),1);
           locationAgents(indexJ).visX = locationX(visLocation) + rand() - 0.5;
           locationAgents(indexJ).visY = locationY(visLocation) + rand() - 0.5;
       end
   end
end

%construct a network among agents according to parameters specified in
%networkParameters.  Any change in network structure should modify/replace
%the createNetwork function
[network, distanceMatrix ] = createNetwork(locations, mapParameters, agentList, networkParameters);


%create the set of moving costs, now that we have a distance matrix made
[movingCosts ] = createMovingCosts(locations, distanceMatrix);


%package everything up
utilityVariables.utilityLayerFunctions = utilityLayerFunctions;
utilityVariables.utilityHistory = utilityHistory;
utilityVariables.utilityAccessCosts = utilityAccessCosts;
utilityVariables.utilityTimeConstraints = utilityTimeConstraints;
utilityVariables.utilityAccessCodesMat = utilityAccessCodesMat;
utilityVariables.utilityBaseLayers = utilityBaseLayers;

mapVariables.map = map;
mapVariables.locations = locations;
mapVariables.borders = borders;
mapVariables.network = network;
mapVariables.distanceMatrix = distanceMatrix;
mapVariables.remittanceFee = remittanceFee;
mapVariables.remittanceRate = remittanceRate;
mapVariables.movingCosts = movingCosts;

%Assign initial income portfolios to agents
[ agentList ] = assignInitialLayers( agentList, utilityVariables );


%visualize the map
[mapHandle] = visualizeMap(agentList, mapVariables, mapParameters);

mapVariables.mapHandle = mapHandle;


end

