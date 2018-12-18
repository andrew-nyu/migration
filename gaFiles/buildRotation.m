function rotation = buildRotation(cropParameters, gAParameters, timeSteps)

%this function is specific to this particular application of the genetic
%algorithm

%returns a rotation of crops, stored as [(length of space) (crop number);
%...]

%figure out how many choices are available for crops
numChoices = length(cropParameters.crops);

%initialize the current length as 0, and the rotation as empty
currentCycleSteps = 0;

rotation = zeros(0,2);
notDone = 1;

%while the rotation has not stopped
while(notDone)
    %add a random length of break space between crops, up to maxSpacing in
    %size
    currentSpacing = randperm(gAParameters.maxSpacing,1);
    
    %pick a crop at random and add it, along with currentSpacing, to the
    %rotation
    currentCrop = randperm(numChoices,1);
    rotation(end+1,:) = [currentSpacing  currentCrop];
    
    %calculate what turn this new addition reaches
    currentCycleSteps = mod(currentCycleSteps + currentSpacing + cropParameters.crops(currentCrop).length, timeSteps.cycle);
    
    %determine whether we end the rotation here, with the likelihood of
    %terminating being higher as we approach zeroTurn (i.e., the more full
    %a cycle is, the more likely we are to stop there.  if we go past it
    %into the next cycle, we will continue adding)
    if(rand() > 1 - currentCycleSteps/gAParameters.zeroTurn)
        notDone = 0;
    end
end