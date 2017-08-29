function [ utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat, utilityBaseLayers ] = createUtilityLayers(locations, timeSteps, dataPath )
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

utilityLayerFunctions{1,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{2,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{3,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{4,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{5,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{6,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{7,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{8,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{9,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer


%prepare the additional arrays necessary to describe the utility layers 

utilityHistory = zeros(length(locations),length(utilityLayerFunctions),timeSteps);
utilityBaseLayers = -9999 * ones(length(locations),length(utilityLayerFunctions),timeSteps);
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
    [1 0.5; %accessing layer 1 is a 25% FTE commitment
    2 0.5; %accessing layer 2 is a 50% FTE commitment
    3 0.5; %accessing layer 2 is a 50% FTE commitment
    4 0.5; %accessing layer 2 is a 50% FTE commitment
    5 0.5; %accessing layer 2 is a 50% FTE commitment
    6 0.5; %accessing layer 2 is a 50% FTE commitment
    7 0.5; %accessing layer 2 is a 50% FTE commitment
    8 0.5; %accessing layer 2 is a 50% FTE commitment
    9 0.5]; %accessing layer 3 is a 50% FTE commitment

utilityAccessCodesMat = false(length(locations),length(utilityLayerFunctions),size(utilityAccessCosts,1));

utilityAccessCodesMat(:,2:3,1) = true; %code 1: all locations require 'licence 1' to access layers 2 and 3
utilityAccessCodesMat(locations.AdminUnit1 == 2, 2:3,2) = true; %code 2: country 2 requires 'licence 2' for layers 2 and 3
utilityAccessCodesMat(locations.AdminUnit1 == 2, 3,3) = true; %code 3: country 2 requires 'licence 3' for layer 3


%define base layer for utility function (i.e., 'averages' from which to
%work)

baseLayer = readtable(dataPath);

%establish the overlap between the points in the map, and the points in the
%data provided.  points not in the data will be -9999
[b_baseLayerLocation,i,j_baseLayerLocation] = unique(baseLayer(:,{'id_0','id_1'}),'rows');
[c,i_location,i_baseLayer] = intersect([locations.source_ID_0 locations.source_ID_1], [b_baseLayerLocation.id_0 b_baseLayerLocation.id_1],'rows');

%get a list linking each row of the baseLayer to a specific index in the
%'locations' array
temp = -9999 * ones(height(b_baseLayerLocation),1);
temp(i_baseLayer) = i_location;
mapLocationInBaseLayer = temp(j_baseLayerLocation);

[b_EconomicActivity,i,j_EconomicActivity] = unique(baseLayer.id_00);
timeStepColumns = find(startsWith(baseLayer.Properties.VariableNames,'ts'));
timeStepColumnNames = baseLayer.Properties.VariableNames(timeStepColumns);
timeStepPoints = str2double(regexprep(timeStepColumnNames,'ts',''));
%for each period of data that we have
for indexI = 1:length(timeStepColumns)
    %for each economic activity present in the dataset
    for indexJ = 1:length(b_EconomicActivity)
        
        %identify points to be updated.  there should be only one
        %datum for each location-activity pair
        currentMapLocs = mapLocationInBaseLayer(j_EconomicActivity == indexJ);
        
        if(indexI == length(timeStepColumns))
           %last one
            numSteps = max(0,timeSteps + 1 - timeStepPoints(indexI));
            temp = table2array(baseLayer(j_EconomicActivity == indexJ,timeStepColumnNames(indexI))) * ones(1,numSteps);
            
            temp(currentMapLocs < 0,:) = [];
            currentMapLocs(currentMapLocs < 0) = [];
            utilityBaseLayers(currentMapLocs, indexJ, timeStepPoints(indexI):end) = temp;
            
        else
            numSteps = max(0,min(timeSteps,timeStepPoints(indexI+1)) - timeStepPoints(indexI));
            if(numSteps > 0)
                temp = table2array(baseLayer(j_EconomicActivity == indexJ,timeStepColumnNames(indexI))) * ones(1,numSteps);

                temp(currentMapLocs < 0,:) = [];
                currentMapLocs(currentMapLocs < 0) = [];
                utilityBaseLayers(currentMapLocs, indexJ, timeStepPoints(indexI):min(timeSteps,timeStepPoints(indexI+1)-1)) = temp;
            end
        end
        
    end
end

utilityBaseLayers(locations.AdminUnit1 == 2, :,:) = utilityBaseLayers(locations.AdminUnit1 == 2, :,:) * 100000;

%utilityBaseLayers has dimensions of (location, activity, time)

% utilityBaseLayers(locations.AdminUnit1 == 2, 1,1:timeSteps/3) = 700000;
% utilityBaseLayers(locations.AdminUnit1 == 2, 1,timeSteps/3:end) = 0;
% utilityBaseLayers(locations.AdminUnit1 == 1, 1,1:timeSteps/3) = 0;
% utilityBaseLayers(locations.AdminUnit1 == 1, 1,timeSteps/3:end) = 700000;
% 
% utilityBaseLayers(locations.AdminUnit1 == 2, 2,:) = 50000;
% utilityBaseLayers(locations.AdminUnit1 == 1, 2,:) = 200000;
% 
% utilityBaseLayers(locations.AdminUnit1 == 2, 3,:) = 10000;
% utilityBaseLayers(locations.AdminUnit1 == 1, 3,:) = 10000;
end
