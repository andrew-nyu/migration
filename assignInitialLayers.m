function [ agentList ] = assignInitialLayers( agentList, utilityVariables )
%assignInitialLayers initializes who is doing what at the start of the
%simulation

for indexA = 1:length(agentList)
    currentAgent = agentList(indexA);
    
   %some basic temporary code to initialize layers.  ideally this initial
   %distribution is informed by census data or other.  note that layers
   %that agents' access code profile should be updated to capture their
   %respective initial state, though i haven't done that here.
   currentAgent.currentPortfolio = randperm(length(utilityVariables.utilityLayerFunctions),ceil(length(utilityVariables.utilityLayerFunctions)*rand()));

   currentAgent.accessCodesPaid(any(utilityVariables.utilityAccessCodesMat(currentAgent.matrixLocation,currentAgent.currentPortfolio,:),2)) = true;

end

