function [ network, distanceMatrix, listX, listY ] = createNetwork( locations, modelParameters, agentList, networkParameters )
%createNetwork creates a network among agents living in different locations

%returns a sparse matrix network of all connected agents, with (i,j) ==1
%indicating that agents with IDs i and j are connected

%returns the distance matrix between all city centers in the map


%%%%%%%%%%

%we use a sparse matrix for agents where the i or j index corresponds to
%the agent's ID.  A '1' indicates a connection between agents i and j; the
%diagonal is all ones by default
numAgents = length(agentList);
network = speye(numAgents, numAgents);

%in this function the likelihood of an agent in city k having a connection
%to an agent in city m is proportional to the euclidean distance between
%the cities.  This particular function uses the shape of the normal
%distribution.  We order cities by their ID, construct a distance matrix,
%and then draw from a normal pdf to get the 'weighting' applied to each
%entry; their own city will have the highest density, thus highest
%weighting.
sizeX = modelParameters.sizeX;
sizeY = modelParameters.sizeY;

locations = sortrows(locations,'cityID');
[listX, listY] = ind2sub([sizeX sizeY],locations.LocationIndex);
distanceMatrix = squareform(pdist([listX listY]));
distanceProbs = normpdf(distanceMatrix, 0, networkParameters.networkDistanceSD);

numCities = length(listX);

%create lists of agents living in each city now, so that it isn't getting
%repeated for each new connection
agentLocations = cell(length(locations),1);
for indexI = 1:length(locations)
    agentLocations{indexI} = agentList([agentList(:).location] == locations(indexI,1).cityID);
end

%cycle through each agent
for indexI = 1:numAgents
    currentAgent = agentList(indexI);
    
    %calculate the number of network connections they should have
    numConnections = max(0,round(networkParameters.connectionsMean + randn()*networkParameters.connectionsSD));
    
    %identify the column in the distance matrix corresponding to their location
    currentLocation = find(locations.cityID == currentAgent.location);
    
    %create the CDF used in selecting the city location for each connection
    probList = distanceProbs(:,currentLocation);
    probList = cumsum(probList)/sum(probList);
    
    %for each of the connections this agent is being given
    for indexJ = 1:numConnections
        
        %draw a random value
        draw = rand();
        
        %find the city corresponding to that draw in the CDF
        locationID = find(probList > draw);
        locationID = locationID(1);
        
        %make a list of all agents in that city
        locationAgents = agentLocations{locationID};
        listOrder = randperm(size(locationAgents,2));
        matched = false;
        
        %look for an agent that hasn't already got a network connection to
        %our current agent (indicated by a '1' in the sparse network
        %matrix. if we don't find one, just move on to the next potential
        %connection.  when a match is made, add the ID number of the match
        %to the agent's network list.  we will go back at the end and
        %replace this list of ID numbers with a pointer to the actual
        %agents
        while(~matched & ~isempty(listOrder))
            if(~network(currentAgent.id, locationAgents(listOrder(1)).id)) %new connection
                strength = rand();
                network(currentAgent.id, locationAgents(listOrder(1)).id) = strength;
                network(locationAgents(listOrder(1)).id, currentAgent.id) = strength;
                matched = true;
                currentAgentNetworkSize = length(currentAgent.network);
                partnerAgentNetworkSize = length(locationAgents(listOrder(1)).network);
                currentAgent.myIndexInNetwork(currentAgentNetworkSize+1) = partnerAgentNetworkSize+1;
                locationAgents(listOrder(1)).myIndexInNetwork(partnerAgentNetworkSize+1) = currentAgentNetworkSize+1;
                currentAgent.network(end+1) = locationAgents(listOrder(1)).id;
                locationAgents(listOrder(1)).network(end+1) = currentAgent.id;
            end
            listOrder(1) = [];
        end
        
    end
    
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
    currentAgent.network = agentList(currentAgent.network);
end

end

