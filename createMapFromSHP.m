function [ locations, map, borders, mapParameters ] = createMapFromSHP( mapParameters )
%createMapFromSHP - creates a raster map of administrative units defined by the
%input shapefile and associated attribute table

%createMapFromSHP saves results in a .mat file for future use, avoiding the
%need to regenerate map each time.

%shapefile attribute table should have membership in administrative units
%denoted by variables ID_X, where lower X values are higher-order units

%shapefile should include a calculated centroid for each unit, labeled
%Latitude and Longitude

%mapParameters includes a 'density' variable that specifies the number of
%grid cells per degree Lat/Long

%returns a list of final cities and the index of their center
%(single-indexing), along with their membership in higher units

%returns a map of each administrative level

%read in the shapefile if necessary

shapeFileName = regexprep(mapParameters.filePath,'.shp','');

try
    load([shapeFileName '.mat']);
catch
    
    fprintf('No processed map found.  Building from shape file (This can take some time)...\n');
    
    shapeData = shaperead(shapeFileName);
    
    %identify the number of levels requested
    
    structNames = fieldnames(shapeData);
    levels = structNames(strncmp(structNames,'ID_',3));
    levelIndices = find(strncmp(structNames,'ID_',3));
    
    [levels,indexOrder] = sort(levels);
    levelIndices = levelIndices(indexOrder);
    
    numLevels = size(levels,1);
    
    %make sure each record has the same number of levels ... where some
    %areas lack lower-level admin, just copy IDs down to the bottom.
    %structs are a pain to work with so just do this one as a for loop
    for indexI = 1:length(shapeData)
       for indexJ = 2:length(levels)
           if shapeData(indexI).(levels{indexJ}) == 0
               shapeData(indexI).(levels{indexJ}) = shapeData(indexI).(levels{indexJ-1});
           end
       end
    end
    
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
    
    minX = min([shapeData(:).Longitude]);
    maxX = max([shapeData(:).Longitude]);
    minY = min([shapeData(:).Latitude]);
    maxY = max([shapeData(:).Latitude]);
    
    xMargin = (maxX-minX)*0.02;
    yMargin = (maxY-minY)*0.02;
    
    sizeX = round((maxX - minX) + 3 * xMargin) * mapParameters.density;
    sizeY = round((maxY - minY) + 3 * yMargin) * mapParameters.density;
    
    r1 = [mapParameters.density  maxY + yMargin minX - xMargin];
    
    map = zeros(sizeY, sizeX, numLevels + 1);
    map(:,:,1) = 1;  %this to say, the starting condition is that the map is all in one piece
    
    cityCenterLocations = [];
    
    layerNames = {};
    
    divisionCount = 0;
    
    tempMap = zeros(sizeY, sizeX);
    tempBorders = zeros(sizeY, sizeX);
    
    %add a field for the 'matrixID' ... this will be the column/row number of
    %the city in all calculations
    [shapeData(1).matrixID] = [];
    
    %start at the bottom
    totalShapes = length(shapeData);
    fprintf(['Mapping ' num2str(totalShapes) ' polygons ...']);
    newMsg = [];
    for indexJ = 1:length(shapeData)
        outcome = vec2mtx(shapeData(indexJ).Y, shapeData(indexJ).X, tempMap, r1, 'filled');
        tempMap(outcome < 2) = indexJ;
        shapeData(indexJ).matrixID = indexJ;
        if(mod(indexJ / (floor(totalShapes / 4)),1) == 0)
            clearMsg = repmat(sprintf('\b'),1,length(newMsg)-1);
            newMsg = [num2str(floor(indexJ / totalShapes * 100)) '%%'];
            
           fprintf( [clearMsg, newMsg]);
        end
        
    end
    fprintf('\n');
    
    %assign new IDs to units to make sure they are all unique
    idCount = 0;
    adminUnits = zeros(size(shapeData,1),numLevels);
    
    %now assign maps, moving up
    for indexI = 2:numLevels+1
        currentLevelIDs = [shapeData(:).(levels{indexI-1})];
        [bLevel,~,jLevel] = unique(currentLevelIDs);
        temp = idCount + (1:length(bLevel));
        adminUnits(:,indexI-1) = temp(jLevel);
        tempLayer = map(:,:,indexI);
        for indexJ = 1:length(shapeData)
            tempLayer(tempMap == indexJ) = temp(jLevel(indexJ));
        end
        map(:,:,indexI) = tempLayer;
        layerNames{end+1} = ['AdminUnit' num2str(indexI-1)];
        idCount = max(temp) + mapParameters.colorSpacing;
    end
    
    [listY,listX] = setpostn(tempMap,r1,[shapeData(:).Latitude],[shapeData(:).Longitude]);
    
    indexLocations = sub2ind([sizeY sizeX], listY, listX);
    
    %now that we are finished, get rid of the top layer used to start the
    %algorithm
    map(:,:,1) = [];
    
    %now we identify borders as well as mark which administrative units each
    %city belongs to
    borders = zeros(size(map));
    
    %for each layer
    for indexI = 1:numLevels
        tempMap = map(:,:,indexI);
        
        %use image processing tools to identify the edges between bordering
        %units in this layer
        tempBorder = edge(tempMap,'sobel',0.1);
        tempBorder = bwmorph(tempBorder,'diag');
        borders(:,:,indexI) = tempBorder;
    end
    
    cityCenterLocations = [adminUnits(:,end) indexLocations'];
    %store locations in a dataset array
    locations = dataset({[cityCenterLocations listX' listY' adminUnits],'cityID','LocationIndex','locationX','locationY',layerNames{:}});
    locations.matrixID = (1:length(listX))';
    
    mapParameters.sizeX = sizeY;
    mapParameters.sizeY = sizeX;
    mapParameters.r1 = r1;
    
    fprintf('Saving map for re-use.\n');
    save([shapeFileName '.mat'], 'locations', 'map', 'borders', 'mapParameters');
end

end

