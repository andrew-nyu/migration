function [child1, child2] = crossoverPortfolio(parent1, parent2)
    

    
    randSplit = rand(size(parent1,1),1) < 0.5;
    
    child1 = parent1;
    child2 = parent2;
    child1(randSplit == 1,:) = parent2(randSplit == 1, :);
    child2(randSplit == 0,:) = parent1(randSplit == 0, :);
    