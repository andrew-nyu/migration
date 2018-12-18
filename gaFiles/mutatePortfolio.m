function child = mutatePortfolio(parent, mcParams)

    %here a mutation is defined as a point mutation in one of 1) the
    %fraction of land allocated to a rotation 2) the fraction of water
    %allocated to a rotation, or 3) an element of the rotation itself
    
    %start with a copy of the parent
    child = parent;
     
    %randomize the type of mutation
    mutateParameter = randperm(size(parent,1),1);
 
    tempMin = mcParams.Lower(mutateParameter);
    tempMax = mcParams.Upper(mutateParameter);
    tempValue = tempMin + (tempMax-tempMin) * rand();
    if(mcParams.RoundYN(mutateParameter))
        tempValue = round(tempValue);
    end

    parent.parameterValues(mutateParameter) = tempValue;
    


end