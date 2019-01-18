load latestPopulation;

addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');

rng('shuffle');


repeats = 4;
series = 'GA_Output_Run_';
saveDirectory = './Outputs/';

runList = zeros(repeats,1);

parfor indexI = 1:repeats
%for indexI = 1:length(experimentList)
    if(runList(indexI) == 0)
        
        %this next line runs MIDAS using the current experimental
        %parameters
        output = midasMainLoop(bestCalibrationSet, ['Replicate Run ' num2str(indexI)]);
        
        
        functionVersions = inmem('-completenames');
        functionVersions = functionVersions(strmatch(pwd,functionVersions));
        output.codeUsed = functionVersions;
        currentFile = [series num2str(length(dir([series '*']))) '_' datestr(now) '.mat'];
        currentFile = [saveDirectory currentFile];
        
        %make the filename compatible across Mac/PC
        currentFile = strrep(currentFile,':','-');
        currentFile = strrep(currentFile,' ','_');

        saveToFile(bestCalibrationSet, output, currentFile);
        runList(indexI) = 1;
    end
end