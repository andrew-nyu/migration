function mcScriptRun()

clear functions
clear classes

addpath('./Core_MIDAS_Code');
addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');

rng('shuffle');

runName = 'Whatever you want to call this one';
series = 'MC_Run_';
saveDirectory = './Outputs/';

input = [];


%this next line runs the MIDAS model
output = midasMainLoop(input, runName);


functionVersions = inmem('-completenames');
functionVersions = functionVersions(strmatch(pwd,functionVersions));
output.codeUsed = functionVersions;
currentFile = [series num2str(length(dir([series '*']))) '_' datestr(now) '.mat'];
currentFile = [saveDirectory currentFile];
saveToFile(input, output, currentFile);



end

function saveToFile(input, output, filename);
    save(filename,'input', 'output');
end