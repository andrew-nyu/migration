function [startingPoints, endingPoints, cropLengths] = calcRotationLength(cropParameters, currentRotation)

%this function is specific to this particular application of the genetic
%algorithm

%extracts the schedule of planting and harvesting from the stored rotation,
%which is stored more densely, including only a list of [(break length)
%(crop id)]

    %if the rotation isn't empty
    if(~isempty(currentRotation))
        %get the length of each crop from the crop parameters array, using the crop ID in the 2nd column of the rotation
        cropLengths = [cropParameters.crops(currentRotation(:,2)).length]';
        
        %get the total length, including breaks
        totalLengths = [currentRotation(:,1) cropLengths];
        
        %calculate the starting points for each crop and the harvest
        %(ending) points
        startingPoints = currentRotation(:,1) + 1 + [0; sum(cumsum(totalLengths(1:end-1,:),1),2)];
        endingPoints = startingPoints + cropLengths - 1;
    else
        startingPoints = [];
        endingPoints = [];
        cropLengths = [];
    end

end