function outputTrajectory = initializeTrajectories(param)

% Initializes empty water end-use trajectories
H10seconds = timeConversion(param.H);

% Initialize the Time Column with 10-second steps
timeSteps = (0:H10seconds-1) * 10; % Generate seconds from 0 to total seconds
hours = floor(timeSteps / 3600);
minutes = floor((timeSteps - hours * 3600) / 60);
seconds = timeSteps - hours * 3600 - minutes * 60;
outputTrajectory.Time = duration([hours', minutes', seconds']);

names=["Faucet", "Shower", "Toilet", "ClothesWasher", "Dishwasher", "Bathtub"];
for i=1:length(names)
    outputTrajectory.(names(i))=zeros(H10seconds,1);  % Changed from (1,H10seconds) to (H10seconds,1)
end

outputTrajectory.TOTAL = zeros(H10seconds,1);  % Changed from (1,H10seconds) to (H10seconds,1)

end