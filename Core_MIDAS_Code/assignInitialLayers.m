function [ agentList ] = assignInitialLayers( agentList, utilityVariables )
%assignInitialLayers initializes who is doing what at the start of the
%simulation

for indexA = 1:length(agentList)
    currentAgent = agentList(indexA);
    
   %some basic temporary code to initialize layers.  ideally this initial
   %distribution is informed by census data or other.  note that layers
   %that agents' access code profile should be updated to capture their
   %respective initial state, though i haven't done that here.
   %currentAgent.currentPortfolio = randperm(length(utilityVariables.utilityLayerFunctions),ceil(length(utilityVariables.utilityLayerFunctions)*rand()));

   %randomly assign a couple of the initial base layers
   
   currentAgent.currentPortfolio = createPortfolio(find(utilityVariables.utilityBaseLayers(currentAgent.matrixLocation,:,1) ~= -9999),utilityVariables.utilityTimeConstraints, utilityVariables.utilityPrereqs, currentAgent.pAddFitElement);
  
  
   currentAgent.accessCodesPaid(any(utilityVariables.utilityAccessCodesMat(:,currentAgent.currentPortfolio, currentAgent.matrixLocation),2)) = true;

   currentAgent.firstPortfolio = currentAgent.currentPortfolio;
end

