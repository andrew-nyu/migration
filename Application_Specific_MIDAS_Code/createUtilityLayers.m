function [ utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat, utilityPrereqs, utilityBaseLayers, utilityForms, incomeForms, nExpected, hardSlotCountYN ] = createUtilityLayers(locations, modelParameters, demographicVariables )
%createUtilityLayers defines the different income/utility layers (and the
%functions that generate them)

%utility layers are described in this model by i) a function used to
%generate a utility value, ii) a set of particular codes corresponding to
%access requirements to use this layer, iii) a vector of costs associated
%with each of those codes, and iv) a time constraint explaining the
%fraction of an agent's time consumed by accessing that particular layer.
%all of these variables are generated here.

%individual layer functions are defined as anonymous functions
%of some set of variables.  any
%additional arguments can be fed by varargin.  the key constraint of the
%anonymous function is that whatever is input must be executable in a
%single line of code - if the structure for the layer is more complicated,
%one must either export some of the calculation to an intermediate variable
%that can be fed to a single-line version of the layer function OR revisit
%this anonymous function structure.

%some parameters only relevant to this file - should be moved to parameters
%file once we're sure.  while they are here, they won't be included in
%sensitivity testing
stepsPerYear = modelParameters.cycleLength;
years = modelParameters.dataTimeSteps;
noise = modelParameters.utility_noise;
iReturn = modelParameters.utility_iReturn;
iDiscount = modelParameters.utility_iDiscount;
iYears = modelParameters.utility_iYears;
leadTime = modelParameters.spinupTime;

numLayers = 6;

%read in raw utility layer data for use below
utilityTable.hdi = readtable([modelParameters.utilityDataPath '/Layers_Region.xlsx'],'Sheet',1);
utilityTable.gni = readtable([modelParameters.utilityDataPath '/Layers_Region.xlsx'],'Sheet',2);
utilityTable.upp = readtable([modelParameters.utilityDataPath '/Layers_Region.xlsx'],'Sheet',3);
utilityTable.rwe = readtable([modelParameters.utilityDataPath '/Layers_Region.xlsx'],'Sheet',4);
utilityTable.dws = readtable([modelParameters.utilityDataPath '/Layers_Region.xlsx'],'Sheet',5);
utilityTable.dep = readtable([modelParameters.utilityDataPath '/Layers_Region.xlsx'],'Sheet',6);

dataYears = startsWith(utilityTable.hdi.Properties.VariableNames,'x');
years = sum(dataYears);

timeSteps = years * stepsPerYear;  

utilityLayerFunctions = [];
for indexI = 1:numLayers  
    %utilityLayerFunctions{indexI,1} = @(k,m,nExpected,n_actual, base) base * (m * nExpected) / (max(0, n_actual - m * nExpected) * k + m * nExpected);   %some income layer - base layer input times density-dependent extinction
    utilityLayerFunctions{indexI,1} = @(k,m,nExpected,n_actual, base) base;   %This simple function is literally just the value of the base layer input
end

%Dimensionality - Utility layer arrays have dimensions of {L, F, T} where L
%is the number of locations, F is the number of layer functions, and T is
%the number of timesteps
utilityHistory = zeros(length(locations),length(utilityLayerFunctions),timeSteps+leadTime);
utilityBaseLayers = -9999 * ones(length(locations),length(utilityLayerFunctions),timeSteps);


%In this application, Layers are (1) HDI, (2) GINI, (3) Urban Population %,
%(4) % of Rural households electrified, (5) % with drinking water (?), and
%(6) Dependency ratio
for indexI = 1:length(locations)          
    utilityBaseLayers(indexI,1,:) = table2array(utilityTable.hdi(utilityTable.hdi.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,2,:) = table2array(utilityTable.gni(utilityTable.hdi.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,3,:) = table2array(utilityTable.upp(utilityTable.hdi.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,4,:) = table2array(utilityTable.rwe(utilityTable.hdi.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,5,:) = table2array(utilityTable.dws(utilityTable.hdi.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,6,:) = table2array(utilityTable.dep(utilityTable.hdi.matrixID == indexI,dataYears));              
end

%estimate expected number of agents for each layer, for use in the utility
%layer function input
locationProb = demographicVariables.locationLikelihood;
locationProb(2:end) = locationProb(2:end) - locationProb(1:end-1);
numAgentsModel = locationProb * modelParameters.numAgents;

nExpected = zeros(length(locations),length(utilityLayerFunctions));
hardSlotCountYN = false(size(nExpected));


%identify which layers have a strict number of openings, and which layers
%do not (but whose average value may decline with crowding)
%hardSlotCountYN(:,1:4) = true; %rental income



%utility layers may be income, use value, etc.  identify what form of
%utility it is, so that they get added and weighted appropriately in
%calculation.  BY DEFAULT, '1' is income.  THE NUMBER IN UTILITY FORMS
%CORRESPONDS WITH THE ELEMENT IN THE AGENT'S B LIST.
utilityForms = zeros(length(utilityLayerFunctions),1);

%Utility form values correspond to the list of utility coefficients in
%agent utility functions (i.e., numbered 1 to n) ... in this case, all are
%income (same coefficient)
utilityForms(1:length(utilityLayerFunctions)) = 2;

%Income form is either 0 or 1 (with 1 meaning income)
incomeForms = utilityForms == 1;

%Consider the meaning of time constraints for this application.  No layers
%are for specific activities, but rather, for aspects of an environment.
%We wish for MIDAS to generate different portfolios for agents to consider
%that range from only including some, to including most or all.  For now we
%leave 'time constraint' as random, but this needs to be more carefully
%considered.

utilityTimeConstraints = zeros(size(utilityLayerFunctions,1),stepsPerYear);
utilityTimeConstraints = rand(size(utilityTimeConstraints));

%define linkages between layers (such as where different layers represent
%progressive investment in a particular line of utility (e.g., farmland)
%AT PRESENT, NO LINKAGES AMONG LAYERS, LEAVE AS ZEROS
utilityPrereqs = zeros(size(utilityTimeConstraints,1));



%now add some lead time for agents to learn before time actually starts
%moving
utilityBaseLayers(:,:,leadTime+1:leadTime+timeSteps) = utilityBaseLayers;
for indexI = leadTime:-1:1
   utilityBaseLayers(:,:,indexI) = utilityBaseLayers(:,:,indexI+modelParameters.cycleLength); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEFINE COSTS TO ACCESS LAYERS
%Define the access costs in two parts - first define specific costs in utilityAccessCosts,
%then associate them with accessing specific layers in utilityAccessCodesMat. Placeholders as examples

%
utilityAccessCosts = ...
    [1 10;... %visa type 1 fee is 1223
     2 20;...
     3 30;...
     4 40;...
     5 50;...
     6 60 ...
    ]; 

utilityAccessCodesMat = false(size(utilityAccessCosts,1),length(utilityLayerFunctions),length(locations));
utilityAccessCodesMat(3,:,1) = true;
utilityAccessCodesMat(2,:,2) = true;
utilityAccessCodesMat(6,:,3) = true;
utilityAccessCodesMat(5,:,4) = true;
utilityAccessCodesMat(4,:,5) = true;
utilityAccessCodesMat(6,:,6) = true;

%code 1: all locations require 'licence 1' to access layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit1 == 2, 2:3,1) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit2 > 40, 2:3,1) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit1 == 2, 3,3) = true; %code 3: country 2 requires 'licence 3' for layer 3

