numAgents = size(output.agentSummary,1);

portfolioData = zeros(numAgents,16,4);

for indexI = 1:numAgents
    temp = output.agentSummary.currentPortfolio{indexI};
    for indexJ = 1:16
        portfolioData(indexI,indexJ,:) = temp((indexJ-1)*4+1:indexJ*4);
    end
end