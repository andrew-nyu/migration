function portfolio = createPortfolio(layers, constraints, prereqs, pAdd)
%createPortfolio draws a random portfolio of utility layers that fit the
%current time constraint

%start with all the time in the world
timeRemaining = ones(1, size(constraints,2)-1);  %will be as long as the cycle defined for layers

%initialize an empty portfolio
portfolio = false(1,size(constraints,1));

%while we still have time left and layers that fit
while(sum(timeRemaining) > 0 && ~isempty(layers))
    
    %draw one of those layers at random and remove it from the set
    randomDraw = ceil(rand()*length(layers));
    
    nextElement = layers(randomDraw);
    layers(randomDraw) = [];
    
    if(~portfolio(nextElement))  %if this one isn't already in the portfolio (e.g., it got drawn in as a prereq in a previous iteration)
        %make a temporary portfolio for consideration

        tempPortfolio = portfolio | prereqs(nextElement,:);

        timeUse = sum(constraints(tempPortfolio,2:end),1);
        timeExceedance = sum(sum(timeUse > 1)) > 0;


        %test whether to add it to the portfolio, if it fits
        if(~timeExceedance & rand() < pAdd)
            portfolio = tempPortfolio;

            %remove any that are OBVIOUSLY over the limit, though this won't
            %catch any that have other time constraints tied to prereqs
            timeRemaining = 1 - timeUse;
            layers(sum(constraints(layers,2:end) > timeRemaining,2) > 0) = [];
        end
    end
end


end

