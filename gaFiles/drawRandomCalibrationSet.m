function experiment = drawRandomCalibrationSet(mcParams)


experiment = table([],[],'VariableNames',{'parameterNames','parameterValues'});
for indexJ = 1:(height(mcParams))
    tempName = mcParams.Name{indexJ};
    tempMin = mcParams.Lower(indexJ);
    tempMax = mcParams.Upper(indexJ);
    tempValue = tempMin + (tempMax-tempMin) * rand();
    if(mcParams.RoundYN(indexJ))
        tempValue = round(tempValue);
    end
    experiment = [experiment;{tempName, tempValue}];
end
