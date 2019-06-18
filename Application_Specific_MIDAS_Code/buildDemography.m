function [locationLikelihood, genderLikelihood, ageLikelihood, survivalRate, fertilityRate, ageDiscountRateFactor, agePointsPopulation, agePointsSurvival, agePointsFertility, agePointsPref] = buildDemography(modelParameters, locations)

%this function can be set up however you like, but is used by MIDAS to
%establish initial distributions of agents and per-period survival in a
%particular way, so that outputs must be structured as follows:

%locationLikelihood is an n x 1 vector providing a cumulative distribution
%scaling from 0 to 1, where n is the number of places in the instance, and
%the interval between element i and the previous element is the likelihood
%of an agent being assigned to place i.  Here, i corresponds to the
%matrixID property of the locations stored in the model map.

%genderLikelihood is an n x 1 vector, in which each element i is the
%likelihood of an agent being MALE in place i

%agePoints is an m x 1 vector of ages at which likelihoods / survival /
%fertility are evaluated.  MIDAS uses interpolation to evaluate ages and survival
%probabilities, so this vector SHOULD include the minimum age (i.e., 0) and
%whatever maximum age you expect in your model.  In most cases, data will
%be in age classes, so agePoints would start with the minimum of the first
%bin and end with the maximum of the last bin.

%ageLikelihood is an n x m_1 x 2 array, where n is the number of places, m_1 is
%the number of points at which age classes are evaluated, and 2 is the
%number of sexes considered by the model (male and female).  Each m-element
%row of ageLikelihood corresponding to place i should be the cumulative
%distribution of ages, for that sex, in place i.

%survivalRate is an n x m_2 x 2 array, where n is the number of places, m_2 is
%the number of points at which age classes are evaluated, and 2 is the
%number of sexes considered by the model (male and female).  Each element
%in survival rate should show the likelihood of ANNUAL (real world years)
%survival of someone that age, sex, and in that location.  MIDAS will
%convert to per-timestep likelihoods

%fertility rate is an n x m_3 array, where n is the number of places, m_3
%is the number of points at which age classes are evaluated.  Each element
%should show the likelihood of a female agent having ONE child.  At present
%MIDAS doesn't worry about multiple births, but also doesn't preclude a
%female agent having a child each timestep, so in practice the number of
%dependents should match the statistical rates well enough

%the following code is specific to a particular input file.

%make locationLikelihood - if there is no data, let the likelihood be
%uniform random
if(~isempty(modelParameters.popFile))
    if(ispc)
        popTable = readtable(modelParameters.popFile);
    else
        popTable = readtable(modelParameters.popFile);
    end
    popTable = popTable(:,{'Country','matrixID','x1990'});
    popTable.Properties.VariableNames{3} = 'population';
    
    popTable = join(popTable,dataset2table(locations),'Keys',{'matrixID'});
    
    
    %this current simple file only has population, so that age/gender
    %likelihoods are still random
    agePointsPopulation = [0 50 100];
    ageLikelihood = ones(length(locations),1) * [0.33 0.66 1];
    ageLikelihood(:,:,2) = ageLikelihood;
    genderLikelihood = rand(length(locations),1);

    locationLikelihood = zeros(length(locations),1);
    locationLikelihood(popTable.matrixID) = popTable.population;
    locationLikelihood = locationLikelihood / sum(locationLikelihood);
    locationLikelihood = cumsum(locationLikelihood);
    
else
    locationLikelihood = ones(length(locations),1) / length(locations);
    locationLikelihood = cumsum(locationLikelihood);
    agePointsPopulation = [0 50 100];
    ageLikelihood = ones(length(locations),1) * [0.33 0.66 1];
    ageLikelihood(:,:,2) = ageLikelihood;
    genderLikelihood = rand(length(locations),1);
end

if(~isempty(modelParameters.survivalFile))
    if(ispc)
        survivalTable = readtable(modelParameters.survivalFile);
    else
        survivalTable = readtable(modelParameters.survivalFile);
    end
    agePointsSurvival = (survivalTable.MaxAge)';
    survivalRate = ones(length(locations),1) * (survivalTable.Male)';
    survivalRate(:,:,2) = ones(length(locations),1) * (survivalTable.Female)';
    survivalRate = 1 - survivalRate;
else
    agePointsSurvival = agePointsPopulation;
    survivalRate =  ones(length(locations),length(agePointsSurvival),2)%1 - rand(length(locations),length(agePointsSurvival),2) / 50;  %this gives annual likelihood of death up to 2%
end

if(~isempty(modelParameters.fertilityFile))
    if(ispc)
        fertilityTable = readtable(modelParameters.fertilityFile);
    else
        fertilityTable = readtable(modelParameters.fertilityFile);
    end
    agePointsFertility = (fertilityTable.MaxAge)';
    agePointsFertility = [fertilityTable.MinAge(1) agePointsFertility];
    fertilityRate = ones(length(locations),1) * (fertilityTable.Births)' / 1000; %this data is births per 1000 women
    fertilityRate = [zeros(length(locations),1) fertilityRate];
else
    agePointsFertility = [15 49];
    fertilityRate = zeros(length(locations),length(agePointsFertility)) %rand(length(locations),length(agePointsFertility)) / 10;  %this gives annual likelihood of birth up to 10%
end

%any additional age-specific factors ought to be handled here
if(~isempty(modelParameters.agePreferencesFile))
    if(ispc)
        agePrefTable = readtable(modelParameters.agePreferencesFile);
    else
        agePrefTable = readtable(modelParameters.agePreferencesFile);
    end
    agePointsPref = (agePrefTable.MaxAge)';
    
    ageDiscountRateFactor = agePrefTable.discRateAge;
    
else
    agePointsPref = [0 100];
    ageDiscountRateFactor = [1 1];  %no change in discount rate with age
end
