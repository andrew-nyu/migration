function [mapHandle] = visualizeMap( agentList, mapVariables )
%visualizeMap shows map and connections

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
imagesc(currentMap);
hold on;

%for each agent
for indexI = 1:length(agentList)
    currentAgent = agentList(indexI);
    
    %make a list of line segments from them to each of their network
    %connections
    endpointsX = [currentAgent.network(:).visX]';
    endpointsY = [currentAgent.network(:).visY]';
    startpointsX = ones(length(endpointsX),1) * currentAgent.visX;
    startpointsY = ones(length(endpointsY),1) * currentAgent.visY;
    
    %plot them using patchline so that they can be translucent
    patchline([startpointsY endpointsY],[startpointsX endpointsX],'EdgeColor',[0 0 0],'EdgeAlpha',0.1);
end

%define the borders as having a value greater than the max cityID
borders = mapVariables.borders * (max(max(currentMap))+10);

%plot country borders, making everything but the border transparent
for indexI = 1:size(borders,3)
    h = imagesc(borders(:,:,indexI));
    set(h,'AlphaData',borders(:,:,indexI) > 0);
end
%fix the colormap so that any cells greater than the max cityID are in white
map = colormap;
map(end,:) = [1 1 1];
colormap(map)

end

