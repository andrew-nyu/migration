%Outer script to set up genetic algorithm and apply to MIDAS calibration

clear all; 
close all;
clear functions
clear classes

addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');

addpath ./gaFiles;

%Set seed for random number generator 
%randSeed = 14;
rng('shuffle');
%randn('state', 'shuffle');

%These are parameters general to the genetic algorithm
gAParameters.minSize = 2; %hectares
gAParameters.maxSpacing = 8; %turns
gAParameters.zeroTurn = 60; %probability of adding another cycle to a rotation scales from 1 down to 0 at zeroTurn
gAParameters.sizeGeneration = 100; %number of candidates in population
gAParameters.generations = 100; %number of generations in algorithm
gAParameters.pCrossover = 0.9; %probability that propagation is by crossover
gAParameters.pMutate = 0.01; %probability that propagation is by mutation
gAParameters.pReproduce = 1 - gAParameters.pCrossover - gAParameters.pMutate; %probability that propagation is by direct reproduction
gAParameters.selectionMethod = 1; %flag for method of selection of candidates
gAParameters.tournamentSize = 5; %size of tournament pool for tournament selection
gAParameters.changeScoreRounds = 5; %number of rounds over which to evaluate change in outcomes (for early breakout from algorithm)
gAParameters.changeScoreTol = 0.001; %tolerance of difference in outcomes to allow an early breakout from algorithm
gAParameters.isBestFitnessMin = 1; %flag ... if 1 then best fitness is minimum, otherwise is maximum
gAParameters.rawFitnessWeights = [1 1 1];

[bestPortfolio, fitnessHistory, population]  = newPopulation(gAParameters);


