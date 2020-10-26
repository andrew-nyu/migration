function minR2 = evaluateModelFit(experimentDirectory, fracMigsData)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% diego: the function now takes two arguments. experimentDirectory is to
% indicate where the model outputs are located. fracMigsData contains the
% empirical data used for calibration. As it is the same for every
% evaluation of model fit, it is calculated only once in 
% runMIDAS_ABCCalibration.m. the function now returns the calculated minR2 
% so that runMIDAS_ABCCalibration.m can calculate the R2 difference between
% several rounds and choose to stop. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clear all;
%close all;

quantileMarker = 0.01;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% diego: regionMembership is a matrix where a region is associated to each
% country. this is used later to aggregate our model generated country 
% level flows to regional level flows.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
countryData=csvread("./Data/Global_Calibration_Data/countriesbyregion.csv");
regionMembership=countryData(:,3);
regionMembership=regionMembership(regionMembership~=0);
   

try
    % diego: evaluationOutputs is not being calculated nor saved, hence 
    % this will never happen
    load evaluationOutputs;
catch
    fileList = dir([experimentDirectory 'MC*.mat']);
        
    skip = false(length(fileList),1);
    for indexI = 1:length(fileList)
        try
            currentRun = load([experimentDirectory fileList(indexI).name]);
            
            fprintf(['Run ' num2str(indexI) ' of ' num2str(length(fileList)) '.\n']);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % diego: now comes a simple data treatment to first remove the
            % countries that are not present in Raftery's data from our
            % model generated data. Then the reamaining country by country
            % data is agrgegated in regions in the same way that raftery's
            % data was aggregated in the function buildMigrationData (l.15
            % of this script)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            
            % diego: loading the migrationMatrix to be treated
            migrationMatrix_agg=currentRun.output.migrationMatrix;
            
            % diego: assigning NaNs to all the countries absent from
            % Raftery's data
            for indexJ = 1:length(countryData)
                if countryData(indexJ,2)==0
                    migrationMatrix_agg(indexJ,:)=NaN;
                    migrationMatrix_agg(:,indexJ)=NaN;
                end    
            end

            % diego: removing nans from the model generated migration data
            migrationMatrix_agg = migrationMatrix_agg(:,~all(isnan(migrationMatrix_agg)));
            migrationMatrix_agg = migrationMatrix_agg(~all(isnan(migrationMatrix_agg),2),:);

            % diego: aggregate countries by region
            migrationMatrix_agg=aggregateByRegion(migrationMatrix_agg,regionMembership);
            
          
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % diego: this is the end of the country elimination-aggregation
            % treatment. the relative number of migrations of the model
            % output and the r2 are calculated like in andrew's 
            % buildNextRound file 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            fracMigsRun = migrationMatrix_agg / sum(sum(migrationMatrix_agg));
            fracMigs_r2 = weightedPearson(fracMigsRun(:), fracMigsData(:), ones(numel(fracMigsRun),1));
      
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % diego: currentOutputRun is simplified as all the other 
            % metrics that were being used in andrew's script are not
            % considered, just fracMigs_r2
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            currentInputRun = array2table([currentRun.input.parameterValues]','VariableNames',strrep({currentRun.input.parameterNames{:}},'.',''));
            currentOutputRun = table(fracMigs_r2,'VariableNames',{'fracMigs_r2'});
            
            % storing results 
            inputListRun(indexI,:) = currentInputRun;
            outputListRun(indexI,:) = currentOutputRun;

        catch
            skip(indexI) = true;
            
        end
        
    end
    
    % removing all the missing data
    skip = skip(1:height(inputListRun));
    inputListRun(skip,:) = [];
    outputListRun(skip,:) = [];
    fileList(skip) = [];
    
end

% diego: using fracMigs_r2 instead than jointFracMigs_r2 as a metric to
% select best runs
minR2 = quantile(outputListRun.fracMigs_r2,[1 - quantileMarker]);
bestInputs = inputListRun(outputListRun.fracMigs_r2 >= minR2,:);

% diego: i assume this is to load mcParams but how do we know that we are loading
% from the desired experiment* file? Since in runMIDASExperiment only the 
% date (and not the time) is saved in the name of the experiment* file, I
% guess that the experiment* file will be overwritten at each calibration
% run as long as all experiments are run on the same day... Can we count on
% that?
expList = dir([experimentDirectory 'experiment_*']);
load([experimentDirectory expList(1).name]);

for indexI = 1:height(mcParams)
    tempIndex = strmatch(strrep(mcParams.Name{indexI},'.',''),inputListRun.Properties.VariableNames);
    mcParams.Lower(indexI) = min(table2array(bestInputs(:,tempIndex)));
    mcParams.Upper(indexI) = max(table2array(bestInputs(:,tempIndex)));
end

% diego: changed the save directory for clarity
save ./Calibration_Outputs/updatedMCParams mcParams;

end
