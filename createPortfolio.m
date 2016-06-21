function portfolio = createPortfolio(layers, constraints)
%createPortfolio draws a random portfolio of utility layers that fit the
%current time constraint

%start with all the time in the world
timeRemaining = 1;

%initialize an empty portfolio
portfolio = zeros(1,length(layers));
currentElement = 1;

%while we still have time left and layers that fit
while(timeRemaining > 0 && ~isempty(layers))
    
    %draw one of those layers at random and remove it from the set
    randomDraw = randperm(length(layers),1);
    nextElement = layers(randomDraw);
    layers(randomDraw) = [];
    
    %add it to the portfolio
    portfolio(currentElement) = nextElement;
    timeRemaining = timeRemaining - constraints(nextElement,2);
    layers(constraints(layers,2) < timeRemaining) = [];  
    currentElement = currentElement + 1;
end
portfolio(portfolio == 0) = [];


end

