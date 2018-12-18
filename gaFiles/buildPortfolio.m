function portfolio = buildPortfolio(farmSize, cropParameters, gAParameters, timeSteps)

%this function is specific to this particular application of the genetic
%algorithm

    %returns a portfolio in the format {(area),(fraction of water),
    %[rotation]}
    
    %initialize the portfolio
    portfolio = cell(0,3);
    
    %initialize the amount of land left to play with as the full farm size
    currentSize = farmSize;
    
    %while land is unallocated
    while(currentSize > 0);
        
        %carve off a new chunk
        newFraction = rand() * farmSize;
        
        %if the new chunk is bigger than the minimum size AND the remainder
        %is bigger than the minimum size
        if(newFraction > gAParameters.minSize && currentSize - newFraction > gAParameters.minSize)
            
            %add a rotation on this chunk of land using the buildRotation
            %function
            newRotation = buildRotation(cropParameters, gAParameters, timeSteps);
            portfolio(end+1,:) = {newFraction, [], newRotation};
            
            %decrement remaining land by the new fraction
            currentSize = currentSize - newFraction;
            
        %otherwise if at least one of the remaining pieces is too small
        %(i.e., we're at the last step)
        elseif(newFraction > gAParameters.minSize || currentSize < gAParameters.minSize)
            
            %add a rotation on all remaining land
            newRotation = buildRotation(cropParameters, gAParameters, timeSteps);
            portfolio(end+1,:) = {currentSize, [], newRotation};
            
            %decrement remaining land to 0
            currentSize = 0;
        end

    end
    
    %now distribute water allocation randomly across all rotations
    waterAlloc = rand(size(portfolio,1),1);
    waterAlloc = waterAlloc/sum(waterAlloc);
    for indexI = 1:size(portfolio,1)
       portfolio{indexI,2} = waterAlloc(indexI); 
    end

end