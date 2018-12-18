function yieldGuess = estYield(cropParameters, i, water)

    %this function is specific to this particular application of the genetic
    %algorithm

    %evaluate the yield from FAO crop parameters and a water estimate of
    %length equal to the crop cycle

    %identify the crop we are evaluating
    currentCrop = cropParameters.crops(i);

    %the base guess is the y0 value
    yieldGuess = currentCrop.y0;

    %for each growth phase of the crop, outlined in the input crop
    %data
    for indexJ = 1:max(currentCrop.period);

        %identify which turns correspond to the current period
        currentBin = currentCrop.period == indexJ;

        %calculate the required ET for this period
        etC = sum(currentBin) * currentCrop.kC(indexJ) * cropParameters.E0;

        %calculate the yield multiplier for this period based on
        %actual ET/ required ET, and the appropriate exponent
        yieldGuess = yieldGuess * (min(sum(water(currentBin))/etC,1)) ^ currentCrop.jC(indexJ);
    end
end % estYield