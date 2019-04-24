function utilityVariables = updateHistory(utilityVariables, modelParameters, indexT, countAgentsPerLayer)

%income functions are of the form f(k,m,nExpected,n_actual, base)
% - note that this may change depending on the simulation -
%be sure that whatever your income functions are, the cellfun input
%matches appropriately

onesList = ones(size(utilityVariables.utilityHistory,1),1);


for indexL = 1:size(utilityVariables.utilityHistory,2)
    utilityVariables.utilityHistory(:,indexL, indexT) = arrayfun(utilityVariables.utilityLayerFunctions{indexL}, ...
        onesList*modelParameters.utility_k, ...
        onesList*modelParameters.utility_m, ...
        onesList*utilityVariables.nExpected(indexL), ...
        countAgentsPerLayer(:,indexL, indexT), ...
        utilityVariables.utilityBaseLayers(:,indexL,indexT));
end

end