function [agent, partner] = interact(agent, partner)
%interact handles the sharing of information between agents


%categorize data in the income layers knowledge of the two agents.  in the
%operation below, data known only to agent get a 1, data known only to
%partner get a 2, and data known by both of them get a 3
overlap = agent.incomeLayersHistory + 2 * partner.incomeLayersHistory;

%agent communicates a fraction of overlap == 1 with partner
agentToPartner = find(overlap == 1);
agentToPartner(rand(length(agentToPartner),1) > agent.knowledgeShareFrac) = [];
partner.incomeLayersHistory(agentToPartner) = true;

%partner communicates a fraction of overlap == 2 with agent
partnerToAgent = find(overlap == 2);
partnerToAgent(rand(length(partnerToAgent),1) > partner.knowledgeShareFrac) = [];
agent.incomeLayersHistory(partnerToAgent) = true;

end

 