function [ locations, map, borders ] = createMap( modelParameters, mapParameters )
%createMap - creates a random map of administrative units defined by the
%number of different divisions given as input

%outputs are city center locations and borders - in the event that these
%spatial data are available for a particular context, they could stand in
%for this routine

%mapParameters.numDivisionMean is a 1xn vector containing the mean number of units within
%each scale...i.e., (1,1) gives the number of countries, (1,2) gives the
%number of states within each country, etc.

%mapParameters.numDivisionMean is a 1xn vector giving the standard deviation of the
%number of units within each scale.  Use 0 to fix the number at the mean

%createMap uses a grid of sizeX and sizeY, with locations only at integer
%locations.  For higher resolution, use larger sizeX and sizeY

%returns a list of final cities and the index of their center
%(single-indexing), along with their membership in higher units

%returns a map of each administrative level

%identify the number of levels requested
numLevels = length(mapParameters.numDivisionMean);
    
%The algorithm reads 'units' as areas in a 2D grid that all have the same
%value.  For each unit it sees at one scale, it will subdivide into m
%different areas at the next scale.

%To start, we make a set of map grids, one for each scale of administration
%plus another to sit on top, just to get the algorithm started

%This top layer gets values of '1' in all cells ... i.e., one 'unit'.  The
%FIRST administrative layer in the input data (i.e., the countries) will be
%constructed in the second layer of this map

%just remember that in this algorithm, indexI+1 refers to the map layer
%corresponding to administrative layer indexI
sizeX = modelParameters.sizeX;
sizeY = modelParameters.sizeY;

map = zeros(sizeX, sizeY, numLevels + 1);
map(:,:,1) = 1;  %this to say, the starting condition is that the map is all in one piece

cityCenterLocations = [];

layerNames = {};

divisionCount = 0;

%for each administrative scale
for indexI = 2:(length(mapParameters.numDivisionMean)+1)

    %find out how many distinct units there were at the higher level
    listLastUnits = unique(map(:,:,indexI-1));
    
    %make new variables for this layer
    currentMap = zeros(sizeX, sizeY);
    layerNames{end+1} = ['AdminUnit' num2str(indexI-1)];
    
    %for each unit in the admin layer above
    for indexJ = 1:length(listLastUnits)
        
        %identify the area of the current unit as 0s
        tempMap = zeros(sizeX, sizeY);
        tempMap(map(:,:,indexI-1) ~= listLastUnits(indexJ)) = -1;
        openList = find(tempMap == 0);
        
        %calculate the number of units to subdivide this area into
        numCurrentUnits = min(length(openList),max(1, round(mapParameters.numDivisionMean(indexI-1) + randn() * mapParameters.numDivisionSD(indexI-1))));
        
        %randomly pick center points for each of these new units within the
        %current area
        currentLocations = openList(randperm(length(openList), numCurrentUnits));
        
        %give each new unit an identifier, spaced away from the previous
        %units' identifiers in order to make divisions clearer in the
        %labeling and color scaling
        currentValues = (divisionCount+1:divisionCount+numCurrentUnits)';
        divisionCount = divisionCount + numCurrentUnits + mapParameters.colorSpacing;

        %if we're at the last layer, then store these center points as the
        %city locations
        if(indexI == numLevels+1)
            cityCenterLocations = [cityCenterLocations; [currentValues currentLocations]];
        end
        
        %switch back from single-indexing to (x,y) coordinates in order to
        %properly capture 2D boundaries, and store the (x,y) coordinates of
        %the city centers as the starting points for our algorithm
        tempMap(currentLocations) = currentValues;
        [currentX, currentY] = ind2sub([sizeX sizeY],currentLocations);

        %while there are still 0s yet to allocate to new subunits
        while(~isempty(currentLocations))
            
           %make a list of all spots in the von neumann neighborhood of our
           %current spots.  add a list of which unit would claim that new
           %spot
           newPotentialSpotsX = [currentX-1; currentX; currentX+1; currentX];
           newPotentialSpotsY = [currentY; currentY+1; currentY; currentY-1];
           newPotentialValues = [currentValues; currentValues; currentValues; currentValues];

           %cut all elements from the list that are out-of-bounds
           newPotentialValues(newPotentialSpotsX > sizeX) = [];
           newPotentialSpotsY(newPotentialSpotsX > sizeX) = [];
           newPotentialSpotsX(newPotentialSpotsX > sizeX) = [];
           newPotentialValues(newPotentialSpotsY > sizeY) = [];
           newPotentialSpotsX(newPotentialSpotsY > sizeY) = [];
           newPotentialSpotsY(newPotentialSpotsY > sizeY) = [];
           newPotentialValues(newPotentialSpotsX < 1) = [];
           newPotentialSpotsY(newPotentialSpotsX < 1) = [];
           newPotentialSpotsX(newPotentialSpotsX < 1) = [];
           newPotentialValues(newPotentialSpotsY < 1) = [];
           newPotentialSpotsX(newPotentialSpotsY < 1) = [];
           newPotentialSpotsY(newPotentialSpotsY < 1) = [];

           %cut all elements from the list that aren't unclaimed (aren't 0)
           newPotentialIndex = sub2ind([sizeX sizeY], newPotentialSpotsX, newPotentialSpotsY);
           alreadyFilled = tempMap(newPotentialIndex) ~= 0;
           newPotentialValues(alreadyFilled) = [];
           newPotentialIndex(alreadyFilled) = [];

           %randomize the order of the list to make each unit's claim to
           %new spots fair
           newOrder = randperm(length(newPotentialValues));
           newPotentialValues = newPotentialValues(newOrder);
           newPotentialIndex = newPotentialIndex(newOrder);

           %cut all elements from the list that are for the same location;
           %i.e., keep only one unit's claim to the new spot
           [currentLocations, indexA, ~] = unique(newPotentialIndex);
           currentValues = newPotentialValues(indexA);
           
           %assign those spots to existing units
           tempMap(currentLocations) = currentValues;

           %update our list of X and Y spots
          [currentX, currentY] = ind2sub([sizeX sizeY],currentLocations);

        end
        
        %add this area to the current map layer
        currentMap(map(:,:,indexI-1) == listLastUnits(indexJ)) = tempMap(map(:,:,indexI-1) == listLastUnits(indexJ));
    
    end
    
    %add this completed map layer to the stack
    map(:,:,indexI) = currentMap;
end

%now that we are finished, get rid of the top layer used to start the
%algorithm
map(:,:,1) = [];

%now we identify borders as well as mark which administrative units each
%city belongs to
borders = zeros(size(map));
adminUnits = zeros(size(cityCenterLocations,1),numLevels);

%for each layer
for indexI = 1:numLevels
    tempMap = map(:,:,indexI);
    
    %mark the administrative unit that owns the location of the city center
    adminUnits(:,indexI) = tempMap(cityCenterLocations(:,2));
    
    %use image processing tools to identify the edges between bordering
    %units in this layer
    tempBorder = edge(tempMap,'sobel',0.1);
    tempBorder = bwmorph(tempBorder,'diag');
    borders(:,:,indexI) = tempBorder;
end

[listX, listY] = ind2sub([sizeX sizeY],cityCenterLocations(:,2));

%store locations in a dataset array
locations = dataset({[cityCenterLocations listX listY adminUnits],'cityID','LocationIndex','locationX','locationY',layerNames{:}});
locations.matrixID = (1:length(listX))';
end

