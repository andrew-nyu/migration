function [ remittanceFee, remittanceRate ] = createRemittanceCosts(locations)
%createRemittanceCosts create remittance cost structures for all scales
%and/or unit pairs in model

%   For n administrative scales there are at least n+1 rates, specified as
%   a fee-rate pair.  While it is possible that fees and rates could be
%   size-specific, we leave that for now as it would be computationally
%   intensive to do an interpolation for all transactions for all agents.
%   Instead, having a specific rate that can be attached to a given
%   unit-unit pair is much more efficient

%   First, specify a fee-rate pair for each scale of administration in an
%   n+1 by 2 array called baseCosts.  The
%   first row is for elements within the same lowest-level unit, the second
%   is for elements within the same next-to-lowest unit, and so on.  the
%   last row is for elements in different highest-level units (e.g.,
%   different countries).  Exceptions for specific unit-unit pairs are made
%   next

baseCosts = [0 0; ... %same district
    0 0; ... %same division, different district
    0 0; ... %same country, different division
    0 0]; %different country



%   Next, make any unit-specific exceptions in an x by 4 array called exceptions, of the form:
%   [unit1 unit2 fee rate; ...].  The unit IDs should correspond to the
%   AdminUnit IDs in 'locations' ... IDs are unique and are not repeated at
%   different scales, so that if the exception is between two units in
%   admin scale 1, choose the ID appropriately.  Most importantly, order
%   the exceptions in reverse order of precedence (i.e., if you have a city-city
%   pair that will supercede a country-country exception, put it after the
%   country-country exception that it supercedes

exceptions = [];% 1 2 20 9; ... %transfers between unit 1 and 2 (country 1 and 2) have a rate of 9
    %116 117 100 0]; % transfers between cities 116 and 117 are more expensive (if these cities exist!!)

%   From here, matrices are created for fees and rates, with indices
%   ordered according to the 'cityID' variable in locations

%make sure the data specified above fits the map
numLocations = size(locations,1);
numScalesSpecified = size(baseCosts,1);
scaleVars = strncmp(locations.Properties.VarNames,'AdminUnit', 9);
numScalesReceived = sum(scaleVars) + 1;
if(numScalesSpecified ~= numScalesReceived)
    error('Remittance costs are incompletely specified for defined locations');
end


locations = sortrows(locations,'matrixID');

%start with the 'same district' costs, and then replace according to each
%scale
remittanceFee = ones(numLocations) * baseCosts(1,1);
remittanceRate = ones(numLocations) * baseCosts(1,2);

%get the lists of admin units
adminLists = double(locations(:,scaleVars));

colsFromRight = 0;
for indexI = 2:numScalesReceived
    currentAdminScale = adminLists(:,end-colsFromRight);
    
    %make an array that has a value of 1 for any two locations that are NOT in
    %the same admin unit
    applicableCells = (currentAdminScale*ones(1,size(currentAdminScale,1))) ~= (currentAdminScale*ones(1,size(currentAdminScale,1)))';
    
    %apply the current admin scale rate and fee to all of these cells
    remittanceFee(applicableCells) = baseCosts(indexI,1);
    remittanceRate(applicableCells) = baseCosts(indexI,2);
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
    remittanceFee(applicableCells) = exceptions(indexI,3);
    remittanceRate(applicableCells) = exceptions(indexI,4);
end

end

