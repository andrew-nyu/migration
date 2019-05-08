clear all;

%here we are looking at the average flood in the last 5 years leading up to
%2080, under different scenarios.  Ideally, we'd see big differences across
%scenarios...

years = 81;
scenario = 1; %%0 is baseline (no shock), 1 is RCP26, 2 is RCP45, and 3 is RCP85

load('probFloods.mat');
load('midasLocations.mat');
storeFloods = zeros(64, years);
normFloodMat = zeros(64,1);
expectedFlood2080Mat = zeros(64,1);
for indexI = 1:length(midasLocations)
    
    %generate the flood history for this location for the next 101 years
    currentLocation = find(cityID_districts == midasLocations.cityID(indexI));
    actualFloods = zeros(years,1);
    for indexJ = 1:years
        if(scenario > 0)
            randDepth = find(rand() < cumProbsMatYear{scenario, currentLocation, indexJ}, 1);
            actualFloods(indexJ) = floodDepth(randDepth);
        end
        
    end
    
    
    %%%define 'normal' flood as the expected flooding in the last year of
    %%%our income data, 2010 (year 11)
    %normalFlood = mean(actualFloods(1:11));
    floodShock = zeros(size(actualFloods));
    if(scenario > 0)
        normalFlood = floodDepth * (cumProbsMatYear{scenario, currentLocation, 11} - [0; cumProbsMatYear{scenario, currentLocation, 11}(1:end-1)]);
        expectedFlood2080 = floodDepth * (cumProbsMatYear{scenario, currentLocation, 81} - [0; cumProbsMatYear{scenario, currentLocation, 81}(1:end-1)]);

        floodShock = actualFloods - normalFlood;
        floodShock(1:11) = 0;
        floodShock = floodShock / 0.3048; %converting meters to feet
        floodShock(floodShock < 0) = 0;
        
    end
    floodShock_0 = [0; floodShock(1:end-1)];  % this is for adding shock to next year
    
    storeFloods(indexI,:) = floodShock;
    normFloodMat(indexI) = normalFlood;
    expectedFlood2080Mat(indexI) = expectedFlood2080;

    
end

%%%%%CHECKING HOW THE FLOOD LOOKS!!!!
banDist = shaperead('ipums_district_level.shp');
normFloodCell = num2cell(normFloodMat);
expectedFloodCell = num2cell(expectedFlood2080Mat);
shockCell = num2cell(mean(storeFloods(:,end-4:end),2));
shockCell2 = num2cell(mean(storeFloods(:,end-24:end),2));
[banDist.normFlood] = normFloodCell{:};
[banDist.shockFlood] = shockCell{:};
[banDist.shockFlood2] = shockCell2{:};
[banDist.expectedFlood] = expectedFloodCell{:};

figure; 
subplot(1,4,1);
axisLimitsColor = [0 5];
normFloodSpec = makesymbolspec('Polygon', {'normFlood', axisLimitsColor, 'FaceColor', hot});
mapshow(banDist, 'DisplayType', 'polygon', 'SymbolSpec', normFloodSpec);
colormap(hot);
colorbar;
title('expected flood (m) 2010');
subplot(1,4,2);
axisLimitsColor = [0 5];
expectedFloodSpec = makesymbolspec('Polygon', {'expectedFlood', axisLimitsColor, 'FaceColor', hot});
mapshow(banDist, 'DisplayType', 'polygon', 'SymbolSpec', expectedFloodSpec);
title('expected flood (m) 2080');
colormap(hot);
colorbar;
subplot(1,4,3);
shockSpec = makesymbolspec('Polygon', {'shockFlood', axisLimitsColor, 'FaceColor', hot});
mapshow(banDist, 'DisplayType', 'polygon', 'SymbolSpec', shockSpec);
title('simulated average flood (m) 2075-80');
colormap(hot);
colorbar;
subplot(1,4,4);
shockSpec2 = makesymbolspec('Polygon', {'shockFlood2', axisLimitsColor, 'FaceColor', hot});
mapshow(banDist, 'DisplayType', 'polygon', 'SymbolSpec', shockSpec2);
title('simulated average flood (m) 2055-80');
colormap(hot);
colorbar;
