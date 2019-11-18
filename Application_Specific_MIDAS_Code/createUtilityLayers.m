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
%of some set of variables.  any additional arguments can be fed by varargin.  
%the key constraint of the anonymous function is that whatever is input must 
%be executable in a single line of code - if the structure for the layer is 
%more complicated,one must either export some of the calculation to an intermediate variable
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

numLayers = 17;

%read in raw utility layer data for use below
utilityTable.poverty     = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',1);
utilityTable.food        = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',2);
utilityTable.health      = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',3);
utilityTable.education   = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',4);
utilityTable.gender      = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',5);
utilityTable.water       = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',6);
utilityTable.energy      = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',7);
utilityTable.economy     = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',8);
utilityTable.innovation  = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',9);
utilityTable.inequality  = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',10);
utilityTable.cities      = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',11);
utilityTable.consumption = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',12);
utilityTable.climate     = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',13);
utilityTable.ocean       = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',14);
utilityTable.land        = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',15);
utilityTable.peace       = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',16);
utilityTable.cooperation = readtable([modelParameters.utilityDataPath '/Layers_Country2.xlsx'],'Sheet',17);

dataYears = startsWith(utilityTable.poverty.Properties.VariableNames,'x');
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


%In this application, Layers are one indicator per SDG, a total of 17
for indexI = 1:length(locations)          
    utilityBaseLayers(indexI,1,:)  = table2array(utilityTable.poverty(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,2,:)  = table2array(utilityTable.food(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,3,:)  = table2array(utilityTable.health(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,4,:)  = table2array(utilityTable.education(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,5,:)  = table2array(utilityTable.gender(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,6,:)  = table2array(utilityTable.water(utilityTable.poverty.matrixID == indexI,dataYears));  
    utilityBaseLayers(indexI,7,:)  = table2array(utilityTable.energy(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,8,:)  = table2array(utilityTable.economy(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,9,:)  = table2array(utilityTable.innovation(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,10,:) = table2array(utilityTable.inequality(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,11,:) = table2array(utilityTable.cities(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,12,:) = table2array(utilityTable.consumption(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,13,:) = table2array(utilityTable.climate(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,14,:) = table2array(utilityTable.ocean(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,15,:) = table2array(utilityTable.land(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,16,:) = table2array(utilityTable.peace(utilityTable.poverty.matrixID == indexI,dataYears));
    utilityBaseLayers(indexI,17,:) = table2array(utilityTable.cooperation(utilityTable.poverty.matrixID == indexI,dataYears));
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
%AT PRESENT, NO LINKAGES AMONG LAYERS, LEAVE AS ZEROS except for 1s along
%diagonal
utilityPrereqs = eye(size(utilityTimeConstraints,1));



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
    [1 0;... 
     2 25;...
     3 50;...
     4 75;
     5 100;
     6 5000...
    ];  

utilityAccessCodesMat = false(size(utilityAccessCosts,1),length(utilityLayerFunctions),length(locations));
% all costs set to 1 in the line above but more of the code below is needed to capture border policies
utilityAccessCodesMat(1,:,[10,11,18,23,26,46,49,54,60,69,71,73,82,98,101,106,108,109,117,119,121,137,140,146,147,148,154,185,188,189,201,202,205,220,231,241,243,251) = true
utilityAccessCodesMat(2,:,[6,16,25,30,33,35,61,64,65,67,76,83,84,92,96,111,112,120,122,135,141,142,150,156,159,163,169,179,191,192,207,216,217,223,230,253,256]) = true
utilityAccessCodesMat(3,:,[15,27,32,38,44,45,47,62,66,88,89,93,103,105,129,131,133,144,149,153,160,161,165,171,172,173,174,178,187,196,210,227,229,236,244,245,248,252,263,264]) = true
utilityAccessCodesMat(4,:,[3,4,12,17,19,24,39,43,48,56,70,72,91,104,114,126,128,132,136,138,139,151,158,180,181,194,197,209,213,232,238,249,250,254,257]) = true
utilityAccessCodesMat(5,:,[2,5,7,22,29,40,41,42,50,55,57,68,74,75,77,113,115,134,145,164,168,182,186,198,206,208,212,214,218,219,222,225,226,235,240,262]) = true
utilityAccessCodesMat(6,:,[1,8,9,13,14,20,21,28,31,34,36,37,51,52,53,58,59,63,78,79,80,81,85,86,87,90,94,95,97,99,100,102,107,110,116,118,123,124,125,127,130,143,152,155,157,162,166,167,170,175,176,177,183,184,190,193,195,199,200,203,204,211,215,221,224,228,233,234,237,239,242,246,247,255,258,259,260,261,265]) = true;


%%MORE EXAMPLES
% utilityAccessCodesMat(1,:,3) = true; %location 3 requires 'license 1' to access all layers

%code 1: all locations require 'licence 1' to access layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit1 == 2, 2:3,1) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit2 > 40, 2:3,1) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit1 == 2, 3,3) = true; %code 3: country 2 requires 'licence 3' for layer 3

