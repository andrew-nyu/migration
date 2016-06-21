# migration
Agent-based model of income selection/migration

Initial set up of project June 21 2016, Andrew Bell

This setup is built in Matlab 2014a.

As built, the model generates a random landscape of hierarchical administrative units (states within countries, districts within states, etc.) and a random network of agents connected with each other, living in these administrative units.  

Agents earn income from layers at fixed intervals which they share with those in their personal networks.  In between these intervals, agents may participate in social interactions with other agents, sharing information about income opportunities, and they may make choose to change their set of income sources - either by choosing new layers in the same place, or moving to a new place.

Agents compare different potential portfolios of income layers by constructing future income streams, converting to expected utility, and discounting those streams back to a net present value.  wherever possible, income streams preserve patterns along time cycles (i.e., seasons) and preserve correlations in time across income layers, thus allowing patterns such as seasonal migration and income diversification to (in theory, with the right parameters) emerge in the simulation.

Future versions of the code will include a batch-run script.  At present, a single simulation run can be made from runMigrationModel.m.  Current configurations include a few layers whose income potential increases down and to the right, leading to a mass migration toward the bottom right corner along the course of the simulation.

Input data to develop different scenarios can be added to the following routines:
1) setupLandscape.m:  all agent preference parameters, random network parameters, landscape size and timestep parameters
2) createUtilityLayers.m: all specifications for utility layers, including the income generation function, time constraint, and access restrictions
3) createMap.m: currently takes data from setupLandscape.m, but could be modified to be fed a specific map
4) assignInitialLayers.m: assigns the initial distribution of income layer use/access ... could be informed by census data
5) createMovingCosts.m: specifies the cost of moving from one place to another in the map
6) createRemittanceCosts.m: specifies the cost of sharing income with others in the social network, across space in the map
