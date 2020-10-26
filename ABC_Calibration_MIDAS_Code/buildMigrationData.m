function fracMigsData = buildMigrationData()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% proper formatting of Raftery data to remove nans and aggregate flows
%% by geographical regions rather than countries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

aggregate=1;

migrationData=csvread("./Data/Global_Calibration_Data/A&R1015_264countries_matrixID.csv",1,1);
countryData=csvread("./Data/Global_Calibration_Data/countriesbyregion.csv");

if aggregate==1
    regionMembership=countryData(:,3);
    regionMembership=regionMembership(regionMembership~=0);
end    

% assigning nans to rows and columns of countries without data
for indexJ = 1:length(countryData)
       if countryData(indexJ,2)==0
           migrationData(indexJ,:)=NaN;
           migrationData(:,indexJ)=NaN;
       end    
end
% removing nans from raftery data
migrationData = migrationData(:,~all(isnan(migrationData)));
migrationData = migrationData(~all(isnan(migrationData),2),:);

if aggregate==1
    migrationData=aggregateByRegion(migrationData,regionMembership);
end    

%one simple metric is the relative # of migrations per source-destination
%pair
fracMigsData = migrationData / sum(sum(migrationData));

end