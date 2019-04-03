function newLink = chooseNewLink(networkParameters, connectionsWeight, distanceWeight, layerWeight, currentConnections, aliveList)

%this is an applications specific function to choose a new connection,
%based on inputs of i) existing network connections, ii) distances to other
%agents, and iii) whether agents work in the same layer (in the same
%place).  any changes to the inputs to this function must be reflected
%appropriately in all other code


%connectionsWeight has values equal to the sum of network weights of all
%shared connections between the current agent and that agent (i.e., if the
%current agent has a 0.1 connection to agent i and a 0.6 connection to
%agent j, and those are the two mutual connections to agent k, then the kth
%entry of connectionsWeight will be 0.7.  in this function, we normalize
%connectionsWeight to scale from 0 to 1, unless the input is all zeros (in
%which case we just leave it alone).
maxWeight = max(connectionsWeight);
if(maxWeight > 0) 
    connectionsWeight = connectionsWeight / maxWeight;
end

%distanceWeight stores the distance to all other agents, in pixel units.  
%we make this nonlinear, so that bigger distances matter more, then
%we normalize this to scale from 0 to 1, and then TAKE THE COMPLEMENT, so
%that the largest scores are those who are closest, with nonlinear decay
temp = distanceWeight;
maxWeight = max(distanceWeight);
if(maxWeight > 0) 
    distanceWeight = distanceWeight.^(networkParameters.distancePolynomial);
    distanceWeight = distanceWeight / max(distanceWeight);
end
distanceWeight = 1 - distanceWeight;

%layerWeight counts the number of shared layer occupations in the current
%place, as a proxy for the number of common places the agents might find
%themselves in.  Again, we normalize to scale from 0 to 1.
maxWeight = max(layerWeight);
if(maxWeight > 0) 
    layerWeight = layerWeight / max(layerWeight);
end

%networkParameters stores the weights by which these different factors
%should be considered
agentFullWeight = connectionsWeight * networkParameters.weightNetworkLink + ...
    distanceWeight * networkParameters.weightLocation + ...
    layerWeight * networkParameters.weightSameLayer;

%currentConnections stores the list of current connections, whose weight in
%the final calculation should be 0
agentFullWeight(currentConnections) = 0;
agentFullWeight(~aliveList) = 0;

agentFullWeight = cumsum(agentFullWeight);
agentFullWeight = agentFullWeight / max(agentFullWeight);


newLink = find(agentFullWeight > rand(),1,'first');
