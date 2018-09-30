function [ agent, moved ] = choosePortfolio( agent, utilityVariables, currentT, modelParameters, mapParameters, demographicVariables, mapVariables )
%choosePortfolio.m is the main engine for agents to select an income
%portfolio (and possibly, to move)

%function takes an agent, as well as the current timestep and a number of
%model environment variables.  The only one of these that is written to
%(and thus copied) is the agent itself

%this is a goal-seeking algorithm, but is not an optimization algorithm.
%finding the *best* portfolio of income options in a particular place,
%subject to an overall time constraint and evaluated via a non-linear
%utility function, can be handled by a quadratic knapsack problem in
%polynomial time.  however, this is impractical for an engine that will be
%run millions of times within a single simulation.

%instead of this, the algorithm captures some aspects of goal-seeking
%behavior in a way that is computationally affordable.  

%agents hold on to m 'best portfolios' in each location that they evaluate,
%and use the highest of these as the marker for the potential income
%achievable in that location.  these markers are then used to identify
%which are the 'best locations'

%with these values held in memory, the algorithm is structured as follows:

%1) choose z different locations to compare, where z includes the current
%location, x 'best locations', and y random locations

%2) within each location, choose p different portfolios to compare, where p
%includes m 'best portfolios' and n random portfolios.  if this location is
%the current location, then one of the m best portfolios is the current
%portfolio

%3) for each portfolio, construct an estimated time path of income, based
%on known history for those income layers in that location.  where
%possible, use full cycles of data (i.e., a full year at a time), and when
%filling in gaps, use the same time period for as many layers as possible.
%This is to maximize impacts of patterns over time and correlations across
%layers in the decision (as would matter in seasonal migration, or income
%diversification, respectively).

%4) add in the expected costs to the agent of accessing this layer, as well
%as moving, and build in the expected sharing in of resources from across
%their network (based on most recent intended share in, and expected
%network distances)

%5) compare all portfolios using a net-present value (with discounting) of
%the expected utility (using agent-specific risk coefficient), and choose
%the best one

%6) adopt the best portfolio, moving to new location if appropriate

%algorithm begins below

%as of now, the agent has not decided to move
moved = [];

%choose a set of locations to evaluate - the current location, some other
%good locations from past searches, and a few random new ones.  note that
%matrixLocation is the identifier for the location's index in the location
%vector, so that it can be used directly to index selected locations
currentLocation = agent.matrixLocation;
[sortedLocations,sortedIndex] = sortrows(agent.bestPortfolioValues,-1);
sortedIndex = sortedIndex(sortedLocations > 0);
bestLocations = sortedIndex(1:min(length(sortedIndex),agent.numBestLocation));
otherRandomLocations = find(any(agent.knowsIncomeLocation,2));
randomLocations = otherRandomLocations(randperm(length(otherRandomLocations),min(length(otherRandomLocations),agent.numRandomLocation)));
locationList = [currentLocation; bestLocations; randomLocations];

%remove duplicates
[bSort,iSort] = sort(locationList);
locationList = locationList(iSort([true; diff(bSort)>0]),:);

%make note of the total number of portfolios we expect to evaluate in each
%location
totalNumPortfolios = agent.numBestPortfolio + agent.numRandomPortfolio;

%since we will try to match historical data to the appropriate season,
%create labels for what part of the cycle our historical data and our
%evaluation period are
periodInCycleData = mod(1:currentT,modelParameters.cycleLength);
periodInCycleEvaluation = mod(1:agent.numPeriodsEvaluate,modelParameters.cycleLength);

%set up the discount and risk factors

%this next line builds in a scaling (in practice) of the discount rate
%based on age.  note that this doesn't modify the underlying discount rate,
%but instead scales it based on any input data.  possibly change
discountAgeScaling = interp1(demographicVariables.agePointsPref, demographicVariables.ageDiscountRateFactor, agent.age);

discountFactor = 1./((1+agent.discountRate * discountAgeScaling).^(0:agent.numPeriodsEvaluate-1)');
riskCoeff = 1 - agent.rValue;

%initialize vectors to hold the best-case portfolios and values for each
%location
locationValue = NaN*ones(length(locationList),1);
locationPortfolio = cell(length(locationList),1);
locationAccessCodes = cell(length(locationList),1);
locationMovingCosts = zeros(length(locationList),1);

%for each location, find a good income portfolio - the current portfolio
%(if this is home city), some other good portfolios from past searches, and
%a few random new ones
for indexL = 1:length(locationList)
    
    %initialize a few things - a blank logical matrix to hold the layers
    %active in each portfolio, and the moving cost that will apply to every
    %portfolio in this location
    portfolioSet = (false(totalNumPortfolios,size(utilityVariables.utilityHistory,2))); %rows equal to number of portfolios; columns equal to number of layers
    currentPortfolio = 1;
    currentMovingCost = mapVariables.movingCosts(currentLocation, locationList(indexL));
    locationMovingCosts(indexL) = currentMovingCost;
    
    %first portfolio is the current portfolio if this is the home city
    if(locationList(indexL) == agent.matrixLocation) %currentLocation
        portfolioSet(currentPortfolio,agent.currentPortfolio) = true;
        currentPortfolio = currentPortfolio + 1;
    end
    
    %next add any previous 'best' portfolios
    for indexP = 1:agent.numBestPortfolio %other best portfolios in this location
        nextBest = agent.bestPortfolios{locationList(indexL), indexP};
        if(~isempty(nextBest))
            portfolioSet(currentPortfolio, nextBest) = true;
            currentPortfolio = currentPortfolio + 1;
        end
    end
    
    %last, come up with a few random portfolios to finish
    for indexP = currentPortfolio:totalNumPortfolios
        nextRandom = createPortfolio(find(any(agent.knowsIncomeLocation(locationList(indexL),:),1)),utilityVariables.utilityTimeConstraints, utilityVariables.utilityPrereqs, agent.pAddFitElement);
        if(~isempty(nextRandom))
            portfolioSet(currentPortfolio, nextRandom) = true;
            currentPortfolio = currentPortfolio + 1;
        end
    end
    

    %find the unique portfolios described in the set.  one could just use
    %           portfolioSet = unique(portfolioSet,'rows');
    %but this is inefficient, and this particular operation is the
    %most expensive in the routine.  instead, take advantage of the fact
    %that a logical vector describes a unique binary number, sort the
    %vector of binary numbers and remove duplicates.  way faster.
    binaryPortfolio = bi2de(portfolioSet);
    [bSort,iSort] = sort(binaryPortfolio);
    portfolioSet = portfolioSet(iSort([true; diff(bSort)>0]),:);
       
    %identify which layers are used across any of the portfolios being
    %evaluated (so we can ignore the rest)
    usedIncomeLayers = any(portfolioSet,1);
    
    %also identify how many complete cycles and partial cycles we are
    %needing to fill
    completeCycles = floor(agent.numPeriodsEvaluate / modelParameters.cycleLength);
    extraPeriods = mod(agent.numPeriodsEvaluate, modelParameters.cycleLength);
    
    %mark out what information our agent has - use the global stored array
    %of income  history to access all data for the layers in use, and blank out elements not known to our agent as
    %NaN
    try
    fullHistory = utilityVariables.utilityHistory(locationList(indexL),usedIncomeLayers,1:currentT);
    catch
       f=1; 
    end
    availableHistory = agent.incomeLayersHistory(locationList(indexL),usedIncomeLayers,1:currentT);
    fullHistory(~availableHistory) = NaN;
    
    %make a blank array to hold the estimated time paths for each layer,
    %and reshape our fullHistory array to be the same 2D shape
    numUniqueLayers = size(availableHistory,2);
    portfolioData = NaN * ones(numUniqueLayers,agent.numPeriodsEvaluate);
    fullHistory = reshape(fullHistory,numUniqueLayers,currentT);
    
    %our evaluation period starts in the next timestep, so find points in
    %the data history that are the same part of the cycle (and are complete
    %cycles), for a first pass fill-in of our evaluation data
    startingPoints = currentT+1:-modelParameters.cycleLength:1;
    startingPoints(1) = []; %isn't a complete cycle
    startingPoints(startingPoints < modelParameters.cycleLength) = [];
    %first pass at filling in evaluation period, drawing cycles randomly
    if(~isempty(startingPoints))
        startSamples = startingPoints(ceil(rand(completeCycles,1) * length(startingPoints)));
        for indexI = 1:length(startSamples)
            
            portfolioData(:,(indexI-1)*modelParameters.cycleLength+1:indexI*modelParameters.cycleLength) = fullHistory(:, startSamples(indexI):startSamples(indexI)+modelParameters.cycleLength-1);
            
        end

        if(extraPeriods > 0)
            endSample = startingPoints(ceil(rand() * length(startingPoints)));
            portfolioData(:,(end-extraPeriods+1):end) = fullHistory(:, (endSample+1):endSample+extraPeriods);
        end

    end
    %now go through and fill in the blanks, trying to preserve sequence if
    %possible; and capturing as many layers per sample as possible.  we do
    %this by choosing a layer at random to look for blanks, filling in as
    %much in other layers as possible as we move through this layer, and
    %then continuing on to the next layer
    priorityList = randperm(numUniqueLayers);
    for indexB = 1:length(priorityList)
        
        %pick the layer randomly and identify blank spots
        currentLayer = priorityList(indexB);
        blankElements = find(isnan(portfolioData(currentLayer,:)));
        %while that layer isn't completely filled in, walk through the
        %blank spots and fill in
        while(~isempty(blankElements))
            
            %if the current spot is still blank (might have been filled by
            %a previous action
            if(isnan(portfolioData(currentLayer,blankElements(1))))
                
                %see if there are complete cycles that can be accessed to
                %fill this spot (and others in sequence after, as well as
                %for other layers)
                availableSamples = find(periodInCycleData == periodInCycleEvaluation(blankElements(1)));
                availableSamples(isnan(fullHistory(currentLayer,availableSamples))) = [];
                if(~isempty(availableSamples))
                    %pick one of the full cycles randomly, and use only the
                    %necessary/available amount of it
                    sampleIndex = availableSamples(randperm(length(availableSamples),1));
                    sampleSize = min([modelParameters.cycleLength, currentT - sampleIndex, agent.numPeriodsEvaluate - blankElements(1)]);
                    
                    %identify the overlap of i) available data in sample
                    %and ii) missing data in the evaluation period
                    currentSample = fullHistory(priorityList(indexB:end),sampleIndex:sampleIndex+sampleSize);
                    currentPeriod = portfolioData(priorityList(indexB:end),blankElements(1):blankElements(1)+sampleSize);
                    filledHoles = logical(isnan(currentPeriod) .* ~isnan(currentSample));
                    
                    %fill the holes and then replace the current block in
                    %the evaluation period with this more complete set
                    currentPeriod(filledHoles) = currentSample(filledHoles);
                    portfolioData(priorityList(indexB:end),blankElements(1):blankElements(1)+sampleSize) = currentPeriod;
                else
                    %we don't have full cycles so just work with individual
                    %periods.  pick from available data at random
                    sampleIndex = find(~isnan(fullHistory(currentLayer,:)));
                    
                    sampleIndex = sampleIndex(randperm(length(sampleIndex)));
                    currentNumPeriods = min(length(blankElements),length(sampleIndex));
                    
                    if(~isempty(sampleIndex))
                        %identify any additional layers that can be filled in
                        %with this sample
                        currentSample = fullHistory(priorityList(indexB:end),sampleIndex(1:currentNumPeriods));
                        %currentBlanks = blankElements(1:length(sampleIndex));
                        %currentPeriod = portfolioData(priorityList(indexB:end),blankElements(1:currentNumPeriods));
                        %filledHoles = logical(isnan(currentPeriod) .* ~isnan(currentSample));
                        
                        %fill the holes and then replace the current sample in
                        %the evaluation period with this more complete set

                        %currentPeriod(filledHoles) = currentSample(filledHoles);
                        
                        portfolioData(priorityList(indexB:end),blankElements(1:currentNumPeriods)) = currentSample;

                    else
                        %we don't know ANYTHING about this layer.  it's only here because it's a prerequisite to a layer we knew something about.
                        %in the absence of any better information, set
                        %values to 0 and move on
                        portfolioData(currentLayer, blankElements) = 0;
                        blankElements = [];
                        continue;
                    end
                end
            end
            %remove the element we just addressed from the list
            blankElements(1) = [];
        end
    end
    
    %now evaluate the different portfolios.  first initialize a few arrays
    %to store important things - the portfolio values as well as the lists
    %of access codes that would need to be paid (so we don't have to look
    %them up again)
    numPortfolios = size(portfolioSet,1);
    portfolioValues = zeros(numPortfolios,1);
    portfolioAccessCodes = cell(numPortfolios,1);
    
    %for efficient matrix calculation of npv we need an array that includes
    %only layers in use; portfolioSet is sized to include ALL layers, so we
    %make a subset, and apply UTILITY WEIGHTS
    portfolioSubSet = portfolioSet;
    portfolioSubSet = portfolioSubSet .* agent.bList(utilityVariables.utilityForms)';

    portfolioSubSet(:,~any(portfolioSet,1))=[];
    for indexP = 1:numPortfolios
        
        %dump all layers into a single time series with each element being
        %the sum of expected layer income in each period.  
        currentPortfolio = (portfolioSubSet(indexP,:)  * portfolioData);

        %add sharing in from the network
        if(~isempty(agent.network))
            %estimate the gross intention of sharing in from network
            potentialAmounts = agent.lastIntendedShareIn;
            potentialAmounts(isnan(potentialAmounts)) = 0;
            
            %calculate costs associated with those shares
            remittanceFee = mapVariables.remittanceFee(agent.matrixLocation, [agent.network(:).matrixLocation]);
            remittanceRate = mapVariables.remittanceRate(agent.matrixLocation, [agent.network(:).matrixLocation]);

            remittanceCost = remittanceFee + remittanceRate / 100 .* potentialAmounts;

            
            %discard any potential transfers that exceed agent's threshold
            %for costs (i.e., agent stops making transfers if the
            %transaction costs are too much of the overall cost)
            feasibleTransfers = remittanceCost ./ potentialAmounts < [agent.network(:).shareCostThreshold];
            actualAmounts = sum((potentialAmounts - remittanceCost) .* feasibleTransfers);
            
            %add the actual expected sharing in to each element in the time
            %series
            currentPortfolio = currentPortfolio + actualAmounts;
        end
        
        %add access costs that would need to be paid in order to access the
        %layers in this portfolio.  first identify those necessary and then
        %cancel out those that are already paid.
        accessCostCodes = any(utilityVariables.utilityAccessCodesMat(locationList(indexL),portfolioSet(indexP,:),:),2);
        accessCostCodes(agent.accessCodesPaid(accessCostCodes)) = false;
        newCosts = sum(utilityVariables.utilityAccessCosts(accessCostCodes,2));
        
        %add these costs to the first element in the time series, and store
        %the list for later (in case we choose this portfolio and need to
        %actually pay them)
        currentPortfolio(1) = currentPortfolio(1) - newCosts;
        portfolioAccessCodes{indexP} = accessCostCodes;
        
        %add moving costs appropriate to this location
        currentPortfolio(1) = currentPortfolio(1) - currentMovingCost;
        
        %convert each element to utility using the risk coefficient, and
        %then discount all elements forward to get NPV in utility units
        
        %prospect theory hack - check!!!!
        vSign = sign(currentPortfolio);
        vSign(vSign < 0) = agent.prospectLoss;
        portfolioValues(indexP) = (1/riskCoeff) * (vSign .* (abs(currentPortfolio) .^ riskCoeff)) * discountFactor;
        
    end
    
    %sort them
    [sortedValues,indexSorted] = sort(portfolioValues,'descend');
    
    
    %save the top few to the 'best portfolio' list
    for indexB = 1:min(agent.numBestPortfolio,length(indexSorted))
        agent.bestPortfolios{locationList(indexL), indexB} = portfolioSet(indexSorted(indexB),:);
    end
    
    %save the best for current evaluation
    locationValue(indexL) = sortedValues(1);
    locationPortfolio{indexL} = portfolioSet(indexSorted(1),:);
    locationAccessCodes{indexL} = portfolioAccessCodes{indexSorted(1)};
end

%now identify the best one.  
[~,indexSorted] = sort(locationValue,'descend');
bestLocation = locationList(indexSorted(1));
bestPortfolio = locationPortfolio{indexSorted(1)};


%if the best portfolio isn't where we currently are, we have to move
if(currentLocation ~= bestLocation) 
    
    moved = agent.matrixLocation;
    %pay moving costs
    agent.wealth = agent.wealth - locationMovingCosts(indexSorted(1));
    
    %update location - this includes i) the matrixLocation (which is the
    %location's index in the location vector, ii) the cityID, which is the
    %unique identifier for the city (used in mapping and in distinguishing
    %from other administrative scales), and iii) the visX and visY markers
    %used to place the agent uniquely somewhere in the appropriate
    %lowest-level unit for visualization purposes
    agent.matrixLocation = locationList(indexSorted(1));

    agent.location = mapVariables.locations(agent.matrixLocation,:).cityID;

    locationMapIndex = find(mapVariables.map(:,:,end) == agent.location);
    if(isempty(locationMapIndex))
        %this particular city is either sub-pixel size or shares all pixels with other cities and lost each one
        %SO, just set visLocation to the established location of the city
        %centroid
        visLocation = mapVariables.locations.LocationIndex(agent.matrixLocation);
    else
        visLocation = locationMapIndex(randperm(length(locationMapIndex),1));
    end
    [locationX, locationY] = ind2sub([mapParameters.sizeX mapParameters.sizeY],visLocation);
    agent.visX = locationX + rand() - 0.5;
    agent.visY = locationY + rand() - 0.5;
    
    %mark the agent as having moved
    moved = [moved; agent.matrixLocation];
end

%pay any access costs necessary to make use of this layer
codesToPay = locationAccessCodes{indexSorted(1)};
newCosts = sum(utilityVariables.utilityAccessCosts(codesToPay,2));
agent.wealth = agent.wealth - newCosts;
agent.accessCodesPaid(codesToPay) = true;

%now that we've paid everything, give the new portfolio to the agent
agent.currentPortfolio = bestPortfolio;

end

