function [agentList, aliveList, modelParameters, agentParameters, mapParameters, utilityVariables, mapVariables, demographicVariables] = buildWorld(modelParameters, mapParameters, agentParameters, networkParameters)

%create a map based on the defined administrative structure in
%mapParameters
if(isempty(mapParameters.filePath))
    [locations, map, borders] = createMap( modelParameters, mapParameters);
else
    [locations, map, borders, mapParameters] = createMapFromSHP( mapParameters);
end

%define remittance costs based on these locations
[ remittanceFee, remittanceRate ] = createRemittanceCosts(locations, modelParameters.remitRate);

%establish population density and likelihood of agent locations
[locationLikelihood, genderLikelihood, ageLikelihood, survivalRate, fertilityRate, ageDiscountRateFactor, agePointsPopulation, agePointsSurvival, agePointsFertility, agePointsPref] = buildDemography(modelParameters, locations);

%survival and fertility rates are generated annually and must be recalibrated for current
%timestep
survivalRate = survivalRate.^(1/modelParameters.cycleLength);
fertilityRate = 1 - ((1-fertilityRate).^(1/modelParameters.cycleLength));

demographicVariables.locationLikelihood = locationLikelihood;
demographicVariables.genderLikelihood = genderLikelihood;
demographicVariables.ageLikelihood = ageLikelihood;
demographicVariables.survivalRate = survivalRate;
demographicVariables.fertilityRate = fertilityRate;
demographicVariables.agePointsPopulation = agePointsPopulation;
demographicVariables.agePointsSurvival = agePointsSurvival;
demographicVariables.agePointsFertility = agePointsFertility;
demographicVariables.agePointsPref = agePointsPref;
demographicVariables.ageDiscountRateFactor = ageDiscountRateFactor;


%create utility layers from the set of layers and functions defined in
%createUtilityLayers.m.  Utility is city-specific, not agent-specific, and
%history is stored in one place only, utilityHistory.  Individual agents
%have a sparse matrix of memory with 1s corresponding to utility values
%they experienced or learned.  This structure allows an arbitrarily large
%landscape with an arbitrarily large number of agents, without wasting
%memory
[utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat, utilityPrereqs, utilityBaseLayers, utilityForms, incomeForms, nExpected, hardSlotCountYN] = createUtilityLayers(locations, modelParameters, demographicVariables);

% diego: changing num forms to the number of SDGs==17
%utilityVariables.numForms = max(utilityForms);
utilityVariables.numForms = 17;
utilityVariables.utilityLayerFunctions = utilityLayerFunctions;
utilityVariables.utilityHistory = utilityHistory;
utilityVariables.utilityAccessCosts = utilityAccessCosts;
utilityVariables.utilityTimeConstraints = utilityTimeConstraints;
utilityVariables.utilityAccessCodesMat = utilityAccessCodesMat;
utilityVariables.utilityBaseLayers = utilityBaseLayers;
utilityVariables.utilityForms = utilityForms;
utilityVariables.incomeForms = incomeForms;
utilityVariables.utilityPrereqs = utilityPrereqs;
utilityVariables.nExpected = nExpected;
utilityVariables.hardSlotCountYN = hardSlotCountYN;
utilityVariables.hasOpenSlots = false(size(hardSlotCountYN));


%create agents and randomly allocate them to 'cities' - the term we use
%here for the lowest administrative level
accessCodesPaid = false(size(utilityAccessCosts,1),1);
knowsIncomeLocation = sparse(size(locations,1),size(utilityBaseLayers,2));
incomeLayersHistory = (false(size(utilityBaseLayers)));
expectedProbOpening = zeros(size(knowsIncomeLocation));

agentParameters.init_accessCodesPaid = accessCodesPaid;
agentParameters.init_knowsIncomeLocation = knowsIncomeLocation;
agentParameters.init_incomeLayersHistory = incomeLayersHistory;
agentParameters.init_expectedProbOpening = expectedProbOpening;

%make the list all at once
agentList = repmat(initializeAgent(agentParameters, utilityVariables, 1, 1, 1),1, networkParameters.agentPreAllocation);

%make each element a pointer to a different placeholder object
for indexI = 1:networkParameters.agentPreAllocation
   agentList(indexI) =  initializeAgent(agentParameters, utilityVariables, 1, 1, 1);
end
%create agents, assigning agent-specific properties as appropriate from
%input data
for indexI = 1:modelParameters.numAgents
    %likelihood variables are ordered by matrixID, lowest to highest
    temp = find(locationLikelihood > rand()); %note the 'greater than' test
    locationID = temp(1);
    
    %generate gender, based on location
    gender = 2 - (genderLikelihood(locationID) < rand());  %note the 'less than' test; codes 1 for male, 2 for female
    
    %generate age, based on location and gender.  Extra 0 ensures bounding
    %below
    age = interp1([0 ageLikelihood(locationID,:,gender)],[0 agePointsPopulation],rand());
    
    %currentAgent = initializeAgent(agentParameters, utilityVariables, age, gender, locations(locationID,1).cityID, agentList(indexI));
    currentAgent = initializeAgent(agentParameters, utilityVariables, age, gender, locations(locationID,1).cityID);
    currentAgent.matrixLocation = locations(locationID,:).matrixID;
    currentAgent.moveHistory = [0 currentAgent.matrixLocation];
    currentAgent.DOB = 0;
    currentAgent.id = agentParameters.currentID;
    agentParameters.currentID = indexI + 1;     
    agentList(indexI) = currentAgent;
end

aliveList = sparse([agentList.TOD] < 0 & [agentList.DOB] >= 0);

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
           
           locationAgents(indexJ).moveHistory = [locationAgents(indexJ).moveHistory locationAgents(indexJ).visX locationAgents(indexJ).visY]; 
       end
   else
       [locationX, locationY] = ind2sub([mapParameters.sizeX mapParameters.sizeY],locationMapIndex);
       for indexJ = 1:length(locationAgents)
           visLocation = randperm(length(locationMapIndex),1);
           locationAgents(indexJ).visX = locationX(visLocation) + rand() - 0.5;
           locationAgents(indexJ).visY = locationY(visLocation) + rand() - 0.5;
           
           locationAgents(indexJ).moveHistory = [locationAgents(indexJ).moveHistory locationAgents(indexJ).visX locationAgents(indexJ).visY];
       end
   end
end

%Assign initial income portfolios to agents
[ agentList ] = assignInitialLayers( agentList, utilityVariables );

%construct a network among agents according to parameters specified in
%networkParameters.  Any change in network structure should modify/replace
%the createNetwork function
[network, distanceMatrix ] = createNetwork(locations, mapParameters, agentList, networkParameters, aliveList);


%create the set of moving costs, now that we have a distance matrix made
[movingCosts ] = createMovingCosts(locations, distanceMatrix, modelParameters);


%package everything up

mapVariables.map = map;
mapVariables.locations = locations;
mapVariables.borders = borders;
mapVariables.network = network;
mapVariables.distanceMatrix = distanceMatrix;
mapVariables.remittanceFee = remittanceFee;
mapVariables.remittanceRate = remittanceRate;
mapVariables.movingCosts = movingCosts;


%visualize the map
if(modelParameters.visualizeYN)
    mapVariables.indexT = 0;
    mapVariables.cycleLength = modelParameters.cycleLength;
    [mapHandle] = visualizeMap(agentList(aliveList), mapVariables, mapParameters, modelParameters);
            set(gcf,'Position',mapParameters.position)
        drawnow();
    mapVariables.mapHandle = mapHandle;
end

%Any other miscellaneous world-building operations

modelParameters.cyclesPerTimeStep = 1 / modelParameters.cycleLength;