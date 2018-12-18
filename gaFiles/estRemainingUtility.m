function [utilityGuess] = estRemainingUtility(cropParameters, water, elapsedCycles, portfolio, riskCoefficient, discountRate, turnMemoryPooling, cropExperience, activeCrops)

%this function is specific to this particular application of the genetic
%algorithm

%estimate utility remaining in a particular portfolio choice (assuming some
%amount of time elapsedCycles has passed), uses expected utility function
%and farmer-specific risk preferences

%establish how long a 'cycle' is and how many we have - this could actually be input to
%the function but the list was getting long
lengthCycle = size(water,1);
numCycles = size(water,2);

%farmers are characterized by the number of distinct water 'periods'
%they remember per cycle, 'turnMemoryPooling'.  if the cycle is 52
%periods and they remember 4 distinct periods, turnMemoryPooling is
%13.  actual water history is averaged over these bins
numBins = lengthCycle / turnMemoryPooling;

%this function takes as input a crop portfolio that may already have
%started, and we establish how many turns have elapsed.  this
%function only evaluates completed cycles, so elapsedTurns is an even
%multiple of cycles
elapsedTurns = elapsedCycles * lengthCycle;

%temporary variable for the water history
tempWater = 0 * water;

%collapse the water memory into bins according to the farmer's memory
%type
for indexI = 1:numBins
    tempWater(1+(indexI-1)*turnMemoryPooling:indexI*turnMemoryPooling,:) = ones(turnMemoryPooling,1) * mean(water(1+(indexI-1)*turnMemoryPooling:indexI*turnMemoryPooling,:),1);
end

%water events that actually happened during the current portfolio are
%set aside.  (but will be used again in hypothetically evaluating the
%future)
pastWater = tempWater(:,end-elapsedCycles+1:end);  %i.e., if there are 2 elapsed cycles, take the last 2


%pre-allocate an array for the utility values for each portfolio element in each
%year
numPartitions = size(portfolio,1);
utilityArray = zeros(numPartitions,numCycles);

lengthRotation = zeros(numPartitions,1);

%for each element in the portfolio
for indexP = 1:size(portfolio,1)
    
    %select the current rotation in the portfolio, stored in the 3rd
    %element of the row
    currentParcel = portfolio(indexP,:);
    currentRotation = currentParcel{3};
    
    %pull out the start and end points of different crops in the current
    %rotation (which aren't stored easily in the rotation, to keep it
    %small)
    [startingPoints, endingPoints, cropLengths] = calcRotationLength(cropParameters, currentRotation);
    
    %calculate the length of the rotation, and how many replicates of it we
    %need to look at to estimate utility.  e.g., if we have n = 5 cycles of
    %water data to evaluate a m = 3 cycle rotation, then there are n - m + 1
    %= 3 replicates to look at (cycles 1-3, 2-4, and 3-5)
    lengthRotation(indexP) = sum(currentRotation(:,1)) + sum(cropLengths);
    lengthRotation(indexP) = max(0,ceil(lengthRotation(indexP) / lengthCycle) - elapsedCycles);
    numReplicates = numCycles - lengthRotation(indexP) + 1;
    
    %if the rotation is longer than the number of cycles of data we have,
    %don't discard it - repeat existing cycles in a random ordering at the
    %end, up until we have enough data to evaluate the rotation once
    supplementWater = zeros(size(tempWater,1),0);
    try
    if(numReplicates < 1)
        supplementWater = tempWater(:,ceil(size(tempWater,2)*rand(1,lengthRotation(indexP) - numCycles)));
    end
    catch
        f = 1;
    end
    
        startingPoints = startingPoints - elapsedTurns;
    endingPoints = endingPoints - elapsedTurns;

    %as long as we don't have an empty rotation
    if(lengthRotation(indexP) > 0)
        
        %for each replicate of water memory
        for indexW = 1:numReplicates
            
            %our current water history for use is [(actual water
            %experienced) (one instance of expected future water)
            %(additional cycles as necessary to complete rotation)]
            %AND then scaled by the fraction of the water allocated to this
            %rotation, and divided by area to get water in mm
            currentWater = currentParcel{2} * [pastWater tempWater(:,indexW:indexW+lengthRotation(indexP)-1) supplementWater] / currentParcel{1};
            
            
            %initialize utility at 0
            currentPerTurnUtility = 0;
            
            %for each crop in the rotation
            for indexC = 1:size(currentRotation,1)
                
                %take the current crop
                currentCrop = currentRotation(indexC,2);
                
                %identify the turn it is harvested in
                harvestTurn = endingPoints(indexC);
                
                %initialize NPV at 0
                currentNPV = 0;
                
                %if the current crop is yet to be harvested, estimate the
                %yield per acre from estYield and add the discounted NPV to
                %currentNPV
                if(harvestTurn > elapsedTurns)
                    temp = zeros(harvestTurn - startingPoints(indexC) + 1,1);
                    try
                    temp(:) = currentWater(startingPoints(indexC):harvestTurn);
                    catch
                        f=1;
                    end
                    if(size(temp,1) == 1)
                        f = 1;
                    end
                    currentYield = estYield(cropParameters, currentCrop, temp);
                    currentNPV = currentNPV + currentYield * cropParameters.crops(currentCrop).price * currentParcel{1} / ((1 + discountRate)^(harvestTurn));
                end
                
                %if the current crop has yet to be planted, subtract expected
                %costs from planting as necessary to currentNPV.  Startup
                %costs are paid only if the crop has never been done before
                %(cropExperience == 0); season costs are paid only if the
                %crop is not already being grown this season (activeCrops
                %== 0).  Area costs are paid per area for all crops
                if(startingPoints(indexC) > elapsedTurns)
                    currentNPV = currentNPV - (currentParcel{1} * cropParameters.crops(currentCrop).areaCost) / ((1 + discountRate)^(startingPoints(indexC) - elapsedTurns));
                    if(activeCrops(currentCrop) == 0)
                        currentNPV = currentNPV - cropParameters.crops(currentCrop).seasonCost / ((1 + discountRate)^(startingPoints(indexC) - elapsedTurns));
                        activeCrops(currentCrop) = 1;
                    end
                    if(cropExperience(currentCrop) == 0)
                        currentNPV = currentNPV - cropParameters.crops(currentCrop).startupCost / ((1 + discountRate)^(startingPoints(indexC) - elapsedTurns));
                        cropExperience(currentCrop) = 1;
                    end
                end
                
                %add the NPV from this crop to the utility for this
                %rotation
                currentPerTurnUtility = currentPerTurnUtility + currentNPV * discountRate / (1 - (1 + discountRate)^(-(harvestTurn - elapsedTurns)));
                
            end %rotation
            
            %place the estimated utility for this rotation, using this set
            %of water cycles, in the array for utility
            utilityArray(indexP,indexW) = currentPerTurnUtility;
        end %cycle
        
    end
end %portfolio

%now we have each possible outcome for each rotation given current
%memory. need to calculate likelihood of each different outcome, which
%is a little complicated since rotations have different lengths

%this next block of code sets up an nxp matrix portfolioEvents, where p
%are all the different (equally likely) possible combinations of
%climate and rotation.

%I have found this algorithm challenging to explain, but consider this
%simple example:  5 cycles of data, and a portfolio with rotations of
%length 3, 2, and 1.  If we are to evaluate portfolio-wide utility fairly,
%the utility derived from the rotation of length 2 from cycles 1 to 2, must
%be considered against the utility from rotation of length 1 in both years
%1 and 2.  Thus, 2 events.  In turn, this can happen in two different ways
%within the rotation of length 3 from cycles 1-3 (2-cycle rotation from
%1-2, and from 2-3, each with two possible combinations of 1-cycle event).
%And so on.  Using the notation A_B to mean a rotation of length A starting
%in cycle B, the full set of p events here is:
% 
% 3_1 2_1 1_1
% 3_1 2_1 1_2
% 3_1 2_2 1_2
% 3_1 2_2 1_3
% 3_2 2_2 1_2
% 3_2 2_2 1_3
% 3_2 2_3 1_3
% 3_2 2_3 1_4
% 3_3 2_3 1_3
% 3_3 2_3 1_4
% 3_3 2_4 1_4
% 3_3 2_4 1_5
% 
% with p = 12 different equally likely events to consider in estimating
% expected utility.  Here for clarity the rows represent events (i.e., p * n array), though below in calculation,
% columns are events (n * p array).  The following algorithm constructs the
% above array for an arbitrary number of total data years and set of
% rotation lengths

%exclude from consideration all rotations of length 0 (these happen)
utilityArray(lengthRotation == 0,:) = [];
lengthRotation(lengthRotation == 0) = [];

%initialize our guess for utility at 0
utilityGuess = 0;

%if we have actual rotations to consider (and not just empty ones)
if(~isempty(lengthRotation))
    
    %identify all the different lengths of rotation in the portfolio
    uniqueLengths = unique(lengthRotation);
    
    %the other length of interest is the total number of cycles, since the
    %longest rotation repeats within that
    differentLengths = [uniqueLengths; numCycles];
    
    %calculate the last year within which any of the rotations can start,
    %to fit within our data. e.g., if there are 7 cycles of data, the last
    %instance to consider would start in cycle 6.
    lastStarts = numCycles - uniqueLengths + 1;
    
    %calculate the number of times a rotation of a particular length will
    %repeat within the next-longer rotation.  e.g., a 3-cycle rotation
    %would repeat 3 times within a 5-cycle rotation
    repetitions = differentLengths(2:end) - differentLengths(1:end-1) + 1;
    
    %calculate how many different instances need to be considered for a
    %rotation with length m, given what different rotations of lengths < m
    %are present.  e.g., if there is a rotation of length 5, 3, and 1 -
    %each 1-cycle rotation occurs 3 times in each 3-cycle rotation, which
    %occurs 3 times within each 5-cycle rotation, so that the blockDepth is
    %3 x 3 = 9
    blockDepth = zeros(size(repetitions,1),1);
    tempReps = [1; repetitions];
    for indexI = length(tempReps)-1:-1:1
        blockDepth(indexI) = prod(tempReps(indexI:-1:1));
    end
    
    %we wish to store all different possibilities in an n * p array, for n
    %different rotations under p different combinations, with p
    %representing the total number of different, equally likely utility
    %outcomes given the number of cycles of available data and the
    %different lengths of rotations.  we pre-allocate the size here - it's
    %the wrong size, but it still speeds it up.
    numDifferentEvents = prod(repetitions);
    portfolioEvents = -Inf * ones(numPartitions, numDifferentEvents);
    
    
    %now we start to fill it in.  for each of the different lengths of
    %rotation
    for indexP = length(uniqueLengths):-1:1
        
        %note how many repetitions there are of the current rotation length
        currentReps = repetitions(indexP);
        
        %note the block lengths of this and shorter rotations
        currentBlocks = blockDepth(indexP:end);
        
        %initialize a few important counters for the loop
        currentStart = ones(size(currentBlocks));
        repCount = zeros(size(currentBlocks));
        currentIndex = 0;
        indexL = 1;
        
        %while we haven't reached the last start for the current rotation
        while indexL <= lastStarts(indexP)
            
            %in the portfolioEvents array, for a row corresponding to a
            %rotation of the current length, add utility values from the
            %utility array in blocks of size corresponding to blockLength.
   
            
            %add blockDepth worth of utility values
            portfolioEvents(lengthRotation == uniqueLengths(indexP), currentIndex+1:currentIndex+blockDepth(indexP)) = utilityArray(lengthRotation == uniqueLengths(indexP), indexL) * ones(1,blockDepth(indexP));
            
            %move down the row by blockDepth spaces
            currentIndex = currentIndex + blockDepth(indexP);
            
            %increment our repCount by blockDepth spaces
            repCount = repCount + blockDepth(indexP);
            
            %cycle through our counters for the number of times we've
            %started blocks for all shorter rotations than the current
            %rotation.  if in the current step we are completing a
            %lower-order block, reset that counter, increment the number of
            %times that (and lower-order blocks) has been started, and move
            %the current start index to the appropriate new current year
            for indexR = 1:length(currentStart)
                if(repCount(indexR) == currentBlocks(indexR)  && indexL < lastStarts(indexP))
                    repCount(indexR) = 0;
                    currentStart(1:indexR) = currentStart(indexR) + 1;
                    indexL = currentStart(indexR)-1;
                end
            end
            
            indexL = indexL + 1;
        end
    end
    
    %each column in portfolioEvents is an equally likely event.  apply
    %expected utility formula to estimate utility from the portfolio
    utilityGuess = sum(portfolioEvents);
    utilityGuess = max(0,utilityGuess);
    utilityGuess = utilityGuess.^(1- riskCoefficient)/(1-riskCoefficient);
    utilityGuess = mean(utilityGuess);
end

end
