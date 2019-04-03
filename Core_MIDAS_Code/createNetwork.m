function [ network, distanceMatrix, listX, listY ] = createNetwork( locations, mapParameters, agentList, networkParameters, aliveList )
%createNetwork creates a network among agents living in different locations

%returns a sparse matrix network of all connected agents, with (i,j) ==1
%indicating that agents with IDs i and j are connected

%returns the distance matrix between all city centers in the map


%%%%%%%%%%

%we use a sparse matrix for agents where the i or j index corresponds to
%the agent's ID.  A '1' indicates a connection between agents i and j; the
%diagonal is all ones by default
numAgents = sum([agentList.TOD] < 0 & [agentList.DOB] >= 0);
network = spalloc(networkParameters.agentPreAllocation, networkParameters.agentPreAllocation, networkParameters.nonZeroPreAllocation);
network(1:numAgents,1:numAgents) = speye(numAgents, numAgents);

%in this function the likelihood of an agent in city k having a connection
%to an agent in city m is proportional to the euclidean distance between
%the cities.  This particular function uses the shape of the normal
%distribution.  We order cities by their ID, construct a distance matrix,
%and then draw from a normal pdf to get the 'weighting' applied to each
%entry; their own city will have the highest density, thus highest
%weighting.
sizeX = mapParameters.sizeX;
sizeY = mapParameters.sizeY;

locations = sortrows(locations,'matrixID');
[listX, listY] = ind2sub([sizeX sizeY],locations.LocationIndex);

%now turn these matrix indices into rough estimates of distance, using the
%mapParameters
if(~isempty(mapParameters.r1))
   aveLatitude = mapParameters.r1(2) + sizeX / mapParameters.density / 2;
   longDegToMile = cos(aveLatitude * mapParameters.degToRad);
   
   listX = listX / mapParameters.density * mapParameters.milesPerDeg;
   listY = listY / mapParameters.density * mapParameters.milesPerDeg * longDegToMile;

end


distanceMatrix = squareform(pdist([listX listY]));


%make a list of new connections and randomize order - likelihood of link
%formation is endogenous to network, so earlier links form basis for later
%ones
numAgentConnections = max(0,round(networkParameters.connectionsMean + randn(numAgents,1)*networkParameters.connectionsSD));
connectionList = zeros(sum(numAgentConnections),1);
indexJ = 1;
for indexI = 1:length(numAgentConnections)
    connectionList(indexJ:indexJ+numAgentConnections(indexI)-1) = indexI;
    indexJ = indexJ + numAgentConnections(indexI);
end
connectionList = connectionList(randperm(length(connectionList)));

%other vars to be used
agentLocations = [agentList.matrixLocation];
agentLayers = vertcat(agentList.currentPortfolio);

%cycle through each connection and make it 
for indexI = 1:length(connectionList)
    currentAgent = agentList(connectionList(indexI));
    if(length(currentAgent.network) == numAgents-1)
       %super unlikely case that agent is already connected to every other agent ... just skip it
       continue;
    end
    
    
    %%the next bit of code sets up input to the application-specific
    %%function that generates likelihoods for new links.  may need to be
    %%adjusted depending on application
    
    %create a list of 'shared weighted connections' with other agents; set
    %this weight to 0 for all agents with whom there is already a
    %connection
    connectionsWeight = network(currentAgent.id,1:numAgents)*network(1:numAgents, 1:numAgents);

    %make a list of existing connections
    currentConnections = network(currentAgent.id,:) > 0;

    %create a list of distances to other agents, based on their location
    distanceWeight = distanceMatrix(currentAgent.matrixLocation,agentLocations);
        
    %create a list of shared layers (in same location)
    layerWeight = currentAgent.currentPortfolio * ((agentLocations == currentAgent.matrixLocation)'*ones(1,size(agentLayers,2)))';
    
    %identify the new network link using the appropriate function for this
    %simulation
    newAgentConnection = chooseNewLink(networkParameters, connectionsWeight, distanceWeight, layerWeight, currentConnections, aliveList);
    connectedAgent = agentList(newAgentConnection);
    
    %now update all network parameters
    strength = rand();
    network(currentAgent.id, connectedAgent.id) = strength;
    network(connectedAgent.id, currentAgent.id) = strength;
    
    currentAgentNetworkSize = length(currentAgent.network);
    partnerAgentNetworkSize = length(connectedAgent.network);
    currentAgent.myIndexInNetwork(currentAgentNetworkSize+1) = partnerAgentNetworkSize+1;
    connectedAgent.myIndexInNetwork(partnerAgentNetworkSize+1) = currentAgentNetworkSize+1;
    currentAgent.network(end+1) = connectedAgent.id;
    connectedAgent.network(end+1) = currentAgent.id;
   
end


%now that all the lists are complete, go back and replace the lists of id
%numbers with actual agent lists, for speed.  this works only now because
%the sorted agent list will have agent IDs running from 1 to n, so that the
%stored id numbers are the same as the list ordering.  won't work later
%when agent list is incomplete

[~,sortAgentOrder] = sort([agentList(:).id]);
agentList = agentList(sortAgentOrder);
for indexI = 1:numAgents
    currentAgent = agentList(indexI);
    try
    currentAgent.network = agentList(currentAgent.network);
    catch
        f=1;
    end
end

end

