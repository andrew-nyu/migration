function migrationRegions=aggregateByRegion(migrationMatrix, regionMembership)

migrationRegions=zeros(max(regionMembership),max(regionMembership));

for i=1:size(migrationMatrix,1)
    region1=regionMembership(i);
    for j=1:size(migrationMatrix,2)
        region2=regionMembership(j);
        
        migrationRegions(region1,region2)=migrationRegions(region1,region2)+migrationMatrix(i,j);
        
    end    
end
end
