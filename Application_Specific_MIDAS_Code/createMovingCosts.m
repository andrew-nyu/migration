function [movingCosts ] = createMovingCosts(locations, distanceMatrix, mapParameters)
%createMovingCosts create moving cost structures for all scales
%and/or unit pairs in model, using scale-specific fixed costs plus distance
%costs

%   For n administrative scales there are at least n+1 rates, specified as
%   a fee-rate pair.  While it is possible that fees and rates could be
%   size-specific, we leave that for now as it would be computationally
%   intensive to do an interpolation for all transactions for all agents.
%   Instead, having a specific rate that can be attached to a given
%   unit-unit pair is much more efficient

%   First, specify a rate for each scale of administration in an
%   n+1 by 1 array called baseMovingCosts.  The
%   first row is for elements within the same lowest-level unit, the second
%   is for elements within the same next-to-lowest unit, and so on.  the
%   last row is for elements in different highest-level units (e.g.,
%   different countries).  Exceptions for specific unit-unit pairs are made
%   next


%   Specify something similar for moving costs between any two spots

baseMovingCosts = [100000; ... %same district
    200000; ... %same state, different district
    500000; ... %same country, different state
    80000000]; %different country

baseMovingCosts = baseMovingCosts * 0;

%   Note any distance-specific costs

%distanceCost = 10;  %per unit distance
distanceCost = mapParameters.movingCostPerMile;%1000;%10000;  %maximum moving cost by distance

%parameters for beta distribution
beta1 = 5;
beta2 = 2;
distanceMin = mapParameters.minDistForCost; %below this distance in miles, we consider it 'free'
distanceMax = mapParameters.maxDistForCost; %above this distance, costs don't really rise


%translate actual distances into their beta distribution equivalent, then
%calculate the distance costs
Db = (distanceMatrix - distanceMin) / (distanceMax - distanceMin);
distanceCost = betacdf(Db,beta1,beta2) * distanceCost;

%   Next, make any unit-specific exceptions in an x by 3 array called exceptions, of the form:
%   [unit1 unit2 rate; ...].  The unit IDs should correspond to the
%   AdminUnit IDs in 'locations' ... IDs are unique and are not repeated at
%   different scales, so that if the exception is between two units in
%   admin scale 1, choose the ID appropriately.  Most importantly, order
%   the exceptions in reverse order of precedence (i.e., if you have a city-city
%   pair that will supercede a country-country exception, put it after the
%   country-country exception that it supercedes

exceptions = []; %1 2 8000; ... %transfers between unit 1 and 2 (country 1 and 2) have a rate of 9
    %116 117 3000]; % transfers between cities 116 and 117 are more expensive (if these cities exist!!)

%   From here, matrices are created for fees and rates, with indices
%   ordered according to the 'cityID' variable in locations

%make sure the data specified above fits the map
numLocations = size(locations,1);
numScalesSpecified = size(baseMovingCosts,1);
scaleVars = strncmp(locations.Properties.VarNames,'AdminUnit', 9);
numScalesReceived = sum(scaleVars) + 1;
if(numScalesSpecified ~= numScalesReceived)
    error('Moving costs are incompletely specified for defined locations');
end


locations = sortrows(locations,'matrixID');

%start with the 'same district' costs, and then replace according to each
%scale

movingCosts = ones(numLocations) * baseMovingCosts(1);

%get the lists of admin units
adminLists = double(locations(:,scaleVars));

colsFromRight = 0;
for indexI = 2:numScalesReceived
    currentAdminScale = adminLists(:,end-colsFromRight);
    
    %make an array that has a value of 1 for any two locations that are NOT in
    %the same admin unit
    applicableCells = (currentAdminScale*ones(1,size(currentAdminScale,1))) ~= (currentAdminScale*ones(1,size(currentAdminScale,1)))';
    
    %apply the current admin scale rate and fee to all of these cells
    movingCosts(applicableCells) = baseMovingCosts(indexI);
    colsFromRight = colsFromRight + 1;
end

%now manage the exceptions in a similar manner
for indexI = 1:size(exceptions,1)
    unit1 = sum(adminLists == exceptions(indexI,1),2);
    unit2 = sum(adminLists == exceptions(indexI,2),2);
    
    %make an array that has a value of 1 for any two locations that ARE in
    %the unit-unit pair specified
    applicableCells = (unit2*unit1' + unit1*unit2') > 0;
    
    %apply the exception fee and rate to all applicable locations
    movingCosts(applicableCells) = exceptions(indexI,3);
end

%now add in the distance-specific costs
%movingCosts = movingCosts + distanceMatrix * distanceCost; %use this line
%if distance cost is a scalar multiple of actual distance, otherwise use the one below

movingCosts = movingCosts +  distanceCost;
movingCosts = movingCosts .* ~eye(size(movingCosts));
end

