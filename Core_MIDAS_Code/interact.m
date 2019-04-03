function [agent, partner] = interact(agent, partner, indexT)
%interact handles the sharing of information between agents


%categorize data in the income layers knowledge of the two agents.  in the
%operation below, data known only to agent get a 1, data known only to
%partner get a 2, and data known by both of them get a 3

%agent.overlap = agent.incomeLayersHistory + 2 * partner.incomeLayersHistory;
%agent.overlap(:) = agent.incomeLayersHistory(:) + 2 * partner.incomeLayersHistory(:);
%agent.overlap(:) = agent.incomeLayersHistory(:) & ~partner.incomeLayersHistory(:);


%agent communicates a fraction of overlap == 1 with partner
%agentToPartner = find(agent.overlap == 1);
agentToPartner = find(agent.incomeLayersHistory(:) & ~partner.incomeLayersHistory(:));
agentToPartner(rand(length(agentToPartner),1) > agent.knowledgeShareFrac) = [];
partner.incomeLayersHistory(agentToPartner) = true;

%partner communicates a fraction of overlap == 2 with agent
%partnerToAgent = find(agent.overlap == 2);
partnerToAgent = find(partner.incomeLayersHistory(:) & ~agent.incomeLayersHistory(:));
partnerToAgent(rand(length(partnerToAgent),1) > partner.knowledgeShareFrac) = [];
agent.incomeLayersHistory(partnerToAgent) = true;
%%%%%%%%%%%%%



%separately, allow agents to share more recent knowledge of available
%openings.  
agentToPartner = find(agent.timeProbOpeningUpdated > partner.timeProbOpeningUpdated);
agentToPartner(rand(length(agentToPartner),1) > agent.knowledgeShareFrac) = [];
partner.heardOpening(agentToPartner) = agent.heardOpening(agentToPartner);
partner.timeProbOpeningUpdated(agentToPartner) = agent.timeProbOpeningUpdated(agentToPartner);

partnerToAgent = find(partner.timeProbOpeningUpdated > agent.timeProbOpeningUpdated);
partnerToAgent(rand(length(partnerToAgent),1) > partner.knowledgeShareFrac) = [];
agent.heardOpening(partnerToAgent) = partner.heardOpening(partnerToAgent);
agent.timeProbOpeningUpdated(partnerToAgent) = partner.timeProbOpeningUpdated(partnerToAgent);

end

 