function [ utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat, utilityPrereqs, utilityBaseLayers, utilityForms, incomeForms, nExpected, hardSlotCountYN ] = createUtilityLayers(locations, modelParameters, demographicVariables )
%createUtilityLayers defines the different income/utility layers (and the
%functions that generate them)

%utility layers are described in this model by i) a function used to
%generate a utility value, ii) a set of particular codes corresponding to
%access requirements to use this layer, iii) a vector of costs associated
%with each of those codes, and iv) a time constraint explaining the
%fraction of an agent's time consumed by accessing that particular layer.
%all of these variables are generated here.

%at present, individual layer functions are defined as anonymous functions
%of x, y, t (timestep), and n (number of agents occupying the layer).  any
%additional arguments can be fed by varargin.  the key constraint of the
%anonymous function is that whatever is input must be executable in a
%single line of code - if the structure for the layer is more complicated,
%one must either export some of the calculation to an intermediate variable
%that can be fed to a single-line version of the layer function OR revisit
%this anonymous function structure.

%some parameters only relevant to this file - should be moved to parameters
%file once we're sure.  while they are here, they won't be included in
%sensitivity testing
quantiles = 4;
years = 51;
noise = modelParameters.utility_noise;
iReturn = modelParameters.utility_iReturn;
iDiscount = modelParameters.utility_iDiscount;
iYears = modelParameters.utility_iYears;
leadTime = modelParameters.spinupTime;

numLayers = 6;


timeSteps = years * modelParameters.cycleLength;  %2005 to 2015 inclusive

utilityLayerFunctions = [];
for indexI = 1:numLayers  %16 (or 13) different sources, with 4 levels
    utilityLayerFunctions{indexI,1} = @(k,m,nExpected,n_actual, base) base * (m * nExpected) / (max(0, n_actual - m * nExpected) * k + m * nExpected);   %some income layer - base layer input times density-dependent extinction
end


utilityHistory = zeros(length(locations),length(utilityLayerFunctions),timeSteps+leadTime);
utilityBaseLayers = -9999 * ones(length(locations),length(utilityLayerFunctions),timeSteps);


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
incomeForms = utilityForms;

%Utility form values correspond to the list of utility coefficients in
%agent utility functions (i.e., numbered 1 to n) ... in this case, all are
%income (same coefficient)
utilityForms(1:length(utilityLayerFunctions)) = 1;

%Income form is either 0 or 1 (with 1 meaning income)
incomeForms = utilityForms == 1;

%estimate the average # of layers occupied by people at different quantiles
% aveNumSources(isnan(aveNumSources)) = 0;
% diversificationLevel = mean(aveNumSources(1,:,:,:));
% diversificationLevel = ceil(reshape(mean(diversificationLevel,4), quantiles,1));

%thus estimate what the average time constraint per layer must be, overall
% timeConstraint = (1 - noise) ./ diversificationLevel; %average time commitment per period at each quantile level

%since we have pre-requisites linking layers for Q1-4, we need to estimate
%in each new layer, how much the AGGREGATE time constraint changes (e.g.,
%so that Q1 for layer N can take 90% of time, but Q1+Q2 can jointly take
%70% ... as though they've mechanized, or bought machines, etc.
utilityTimeConstraints = zeros(size(utilityLayerFunctions,1),quantiles);
% for indexI = 1:size(timeQs,1)
%     for indexJ = 1:length(timeConstraint)
%         %time constraint for Q(i) should be such that those for 1 through i
%         %add to the value in timeConstraint
%         temp = timeConstraint(indexJ) * timeQs(indexI,:);
%         temp = temp - sum(utilityTimeConstraints(((indexI - 1)*quantiles + 1):((indexI - 1)*quantiles + (indexJ-1)),:),1);
%         utilityTimeConstraints((indexI - 1)*quantiles + indexJ,:) = temp;
%     end
% end

utilityTimeConstraints = rand(size(utilityTimeConstraints));

%define linkages between layers (such as where different layers represent
%progressive investment in a particular line of utility (e.g., farmland)
utilityPrereqs = zeros(size(utilityTimeConstraints,1));
%let the 2nd Quartile require the 1st, the 3rd require 2nd and 1st, and 4th
%require 1st, 2nd, and 3rd for every layer source
% for indexI = 4:4:size(utilityTimeConstraints,1)
%    utilityPrereqs(indexI, indexI-3:indexI-1) = 1; 
%    utilityPrereqs(indexI-1, indexI-3:indexI-2) = 1; 
%    utilityPrereqs(indexI-2, indexI-3) = 1; 
% end
% utilityPrereqs = utilityPrereqs + eye(size(utilityTimeConstraints,1));
% utilityPrereqs = sparse(utilityPrereqs);

%with these linkages in place, need to account for the fact that in the
%model, any agent occupying Q4 of something will automatically occupy Q1,
%Q2, Q3, but at present the values nExpected don't account for this.  Thus,
%nExpected for Q1 needs to add in Q2-4, for Q2 needs to add in Q3-4, etc.
%More generally, all 'expected' values need to be adjusted up to allow for
%all things that rely on them.  This is because of a difference between how
%the model interprets layers (occupying Q4 means occupying Q4 + all
%pre-requisites) and the input data (occupying Q4 means only occupying Q4)
% tempExpected = zeros(size(nExpected));
% for indexI = 1:size(nExpected,2)
%    tempExpected(:,indexI) = sum(nExpected(:,utilityPrereqs(:,indexI) > 0),2); 
% end
% nExpected = tempExpected;

%generate base layers for input; these will be ordered N1Q1 N1Q2 N1Q3 N1Q4
%N2Q1 N2Q2 N2Q3 N2Q4, etc.  (i.e., all layers for one source in order, then
%the next source, etc.)
for indexI = 1:length(locations)
          
    for indexJ = 1:length(utilityLayerFunctions)
        for indexK = 1:quantiles

            
            utilityBaseLayers(indexI,indexJ,:) = rand(timeSteps,1);
            
            
        end
    end
end

%now add some lead time for agents to learn before time actually starts
%moving
utilityBaseLayers(:,:,leadTime+1:leadTime+timeSteps) = utilityBaseLayers;
for indexI = leadTime:-1:1
   utilityBaseLayers(:,:,indexI) = utilityBaseLayers(:,:,indexI+modelParameters.cycleLength); 
end

%placeholders as examples

utilityAccessCosts = ...
    [1 1223; %visa type 1 fee is 1223
     2 231323;
    ]; 

utilityTimeConstraints = ...
    [1 0.5; %accessing layer 1 is a 25% FTE commitment
    2 0.5; %accessing layer 2 is a 50% FTE commitment
    3 0.5; %accessing layer 2 is a 50% FTE commitment
    4 0.5; %accessing layer 2 is a 50% FTE commitment
    5 0.5; %accessing layer 2 is a 50% FTE commitment
    6 0.5]; %accessing layer 3 is a 50% FTE commitment

utilityAccessCodesMat = false(size(utilityAccessCosts,1),length(utilityLayerFunctions),length(locations));
%utilityAccessCodesMat(:,2:3,1) = true; %code 1: all locations require 'licence 1' to access layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit1 == 2, 2:3,1) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit2 > 40, 2:3,1) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
%utilityAccessCodesMat(locations.AdminUnit1 == 2, 3,3) = true; %code 3: country 2 requires 'licence 3' for layer 3

%any hack code for testing ideas can go below here but should be commented
%when not in use...
% utilityAccessCosts(1:quantiles * size(locations,1),2) = 0.2 * utilityAccessCosts(1:quantiles * size(locations,1),2);
