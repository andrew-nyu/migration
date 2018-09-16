 migData = readtable('migration_data_mat.csv');
 
 migData(end,:) = [];
 
 placeNameData = readtable('place_names_mig_data.xlsx');
 load midasLocations;  %this stores the indices and names of the 64 districts as used in MIDAS
 
 %use the names to develop structure of matrix
 tempNames = string(migData.Properties.VariableNames);
 [numName, genderName] = regexp(tempNames(2:end),'\d*','match','split');
 migIndex = zeros(3,length(numName));
 for indexI = 1:length(numName)
     migIndex(1,indexI) = genderName{indexI}(1) == "m";
     migIndex(2,indexI) = str2double(numName{indexI}(1));
     migIndex(3,indexI) = str2double(numName{indexI}(2));
 end

%set up the data as a 64 x 64 x m x 2 array, where 2 is for gender, m is
%for age bins, and 64 is num of locations.  use the MIDAS ordering

%first fix a few place name differences
placeNameData.District{7} = 'Brahmanbaria';
placeNameData.District{24} = 'Jhenaidaha';
placeNameData.District{36} = 'Maulvi Bazar';
placeNameData.District{45} = 'Chapai Nababganj';
placeNameData.District{46} = 'Netrokona';

[c, ia, ib] = intersect(placeNameData.District,midasLocations.source_ADMIN_NAME);


%turn gender and age into indices
[b,i,j] = unique(migIndex(2,:));
migIndex(2,:) = j;

migIndex(1,:) = migIndex(1,:) + 1;

migDataMat = zeros(64, 64, length(b),2);
%now make the index that translates positions in migData into the
%matrixID
transferIndex = sortrows([placeNameData.DistCode(ia) midasLocations.matrixID(ib)]);

migDataArray = table2array(migData);
for indexJ = 1:height(migData)
    currentFromMatrixID = transferIndex(find(transferIndex(:,1) == migData.zila(indexJ)),2);
    if ~isempty(currentFromMatrixID)
        for indexI = 1:length(migIndex)
            currentToMatrixID = transferIndex(find(transferIndex(:,1) == migIndex(3,indexI)),2);
            if ~isempty(currentToMatrixID)
                migDataMat(currentFromMatrixID, currentToMatrixID, migIndex(2, indexI), migIndex(1, indexI)) = migDataArray(indexJ, indexI + 1);
            end
        end
    end
end

migDataFlatMat = (sum(sum(migDataMat,4),3));

interDistrictMoves = migDataFlatMat .* ~eye(64);

close all;
figure;
imagesc(interDistrictMoves);
set(gca,'YTick',1:64, 'XTick',1:64, 'YTickLabel',midasLocations.source_ADMIN_NAME, 'XTickLabel',midasLocations.source_ADMIN_NAME);
xticklabel_rotate;
colorbar;
title(['Interdistrict moves (n = ' num2str(sum(sum(interDistrictMoves))) ')']);
grid on;
colormap hot;
set(gca,'GridColor','white');
temp = ylabel('ORIGIN','FontSize',16);
xlabel('DESTINATION','FontSize',16);
set(temp,'Position', [-.1 .5 0])