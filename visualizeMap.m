function [mapHandle] = visualizeMap( agentList, mapVariables, mapParameters )
%visualizeMap shows map and connections

%actions vary slightly depending on whether map is i) randomly generated or
%ii) is generated from a shapefile (and thus has georeferencing, encoded in
%the 1x3 vector 'r1' in mapParameters)

if(isfield(mapVariables,'mapHandle'))
    mapHandle = mapVariables.mapHandle;
else
    mapHandle = figure;
end

hold off;
%paint a scaled map of all cities.  city numbering will have spacing in
%between those from different states (higher admin level) so that state
%membership is implied by coloring
currentMap = mapVariables.map(:,:,end);
if(isempty(mapParameters.r1))
    imagesc(currentMap);
else
    currentMap(currentMap ==0) = -Inf; %so that the oceans are white.
    hMap = mapshow(currentMap, mapParameters.r1,'CData',currentMap,'displaytype','surface');
end
hold on;

%for each agent
for indexI = 1:length(agentList)
    currentAgent = agentList(indexI);
    
    %make a list of line segments from them to each of their network
    %connections
    endPointsX = [currentAgent.network(:).visX]';
    endPointsY = [currentAgent.network(:).visY]';
    startPointsX = ones(length(endPointsX),1) * currentAgent.visX;
    startPointsY = ones(length(endPointsY),1) * currentAgent.visY;
    
    if(~isempty(mapParameters.r1)) %from shapefile
        [startPointsX,startPointsY] = setltln(currentMap,mapParameters.r1,startPointsX, startPointsY);
        [endPointsX,endPointsY] = setltln(currentMap,mapParameters.r1,endPointsX, endPointsY);
        maxColor = max(max(currentMap));
        if(~isempty(startPointsX))
            %plot them using patchline so that they can be translucent
            patchline([startPointsY endPointsY],[startPointsX endPointsX],(maxColor+1) * ones(size(startPointsY,1),2),'EdgeColor',[0 0 0],'EdgeAlpha',0.1);
        end
    else %random map
        %plot them using patchline so that they can be translucent
        patchline([startPointsY endPointsY],[startPointsX endPointsX],'EdgeColor',[0 0 0],'EdgeAlpha',0.1);
        
    end
    
    %plot them using patchline so that they can be translucent
    patchline([startPointsY endPointsY],[startPointsX endPointsX],'EdgeColor',[0 0 0],'EdgeAlpha',0.1);
    %mapshow([startPointsY endPointsY],[startPointsX endPointsX],'EdgeColor',[0 0 0],'EdgeAlpha',0.1);
end

%define the borders as having a value greater than the max cityID
borders = mapVariables.borders * (max(max(currentMap))+10);

%plot country borders, making everything but the border transparent
for indexI = 1:size(borders,3)
    
    if(isempty(mapParameters.r1)) %random map
        hBorder = imagesc(borders(:,:,indexI));
        set(hBorder,'AlphaData',borders(:,:,indexI) > 0);
    else %shapefile map
        %We can show borders in the shapefile case too, but they're ugly
        
        %hBorder = mapshow(borders(:,:,indexI), mapParameters.r1,'displaytype','surface');
        %set(hBorder,'EdgeColor',[1 1 1]);
    end

end

if(isempty(mapParameters.r1)) %random map
    %fix the colormap so that any cells greater than the max cityID are in white
    map = colormap;
    map(end,:) = [1 1 1];
    colormap(map)
end

end

