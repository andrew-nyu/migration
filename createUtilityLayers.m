function [ utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat ] = createUtilityLayers(locations, timeSteps )
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

utilityLayerFunctions{1,1} = @(x, y, t, n, varargin) 1000;   %some income layer


utilityLayerFunctions{2,1} = @(x, y, t, n, varargin) 50*x + 2000;   %some income layer


utilityLayerFunctions{3,1} = @(x, y, t, n, varargin) 30 *y + 3000;   %some income layer


%prepare the additional arrays necessary to describe the utility layers 

utilityHistory = zeros(length(locations),length(utilityLayerFunctions),timeSteps);
utilityAccessCosts = zeros(length(utilityLayerFunctions),2);

%define the cost of access for utility layers ... payments may provide
%access to different locations (i.e., a license within a state or country)
%or to different layers (i.e., training and certification in related
%fields, or capital investment in related tools, etc.)  

%placeholders as examples

utilityAccessCosts = ...
    [1 100; %code 1 expense is 100
    2 75; %code 2 expense is 75
    3 200]; 

utilityTimeConstraints = ...
    [1 0.25; %accessing layer 1 is a 25% FTE commitment
    2 0.5; %accessing layer 2 is a 50% FTE commitment
    3 0.5]; %accessing layer 3 is a 50% FTE commitment

utilityAccessCodesMat = false(length(locations),length(utilityLayerFunctions),size(utilityAccessCosts,1));

utilityAccessCodesMat(:,2:3,1) = true; %code 1: licence in country 1 gives access to 2 and 3
utilityAccessCodesMat(locations.AdminUnit1 == 12, 2:3,2) = true; %code 2: country 2 requires licence for 2 and 3
utilityAccessCodesMat(locations.AdminUnit1 == 12, 3,3) = true; %code 3: country 2 requires certification for 3

end
