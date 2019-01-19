
function runMIDAS_GAReplicates()

addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');

rng('shuffle');



repeats = 10;
series = 'GA_Output_Run_';
saveDirectoryBase = './GASets/Ban_GA_';

for indexK = 1:11
    
    saveDirectory = [saveDirectoryBase num2str(indexK) '/'];
    
load([saveDirectory 'latestPopulation']);

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
        currentFile = [saveDirectoryBase num2str(indexK) '/' currentFile];
        
        %make the filename compatible across Mac/PC
        currentFile = strrep(currentFile,':','-');
        currentFile = strrep(currentFile,' ','_');

        saveToFile(bestCalibrationSet, output, currentFile);
        runList(indexI) = 1;
    end
end

end

end

function saveToFile(input, output, filename);
    save(filename,'input', 'output');
end