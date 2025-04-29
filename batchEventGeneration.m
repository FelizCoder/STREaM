% Define the parameters
outputFolder = './output/';
nTrainEvents = 10000; % Number of events per appliance to generate for the training set
nTestEvents = 100; % Number of events per appliance to generate for the test set
HHsize = 2; % Household size
appliances = ["HEFaucet", "HEToilet", "HEShower", "HEClothesWasher", "HEDishwasher", "HEBathtub"];


% Load the required data
load database.mat
load pyniwm_features.mat

% intialize data structures
trainStatistics = array2table(zeros(0,9),'VariableNames', {'Label', 'Duration', 'Volume', 'Peak', 'Mean', 'Hour', 'EventStartTime', 'EventStartIdx', 'EventEndIdx'});
trainTrajectories = array2table(zeros(0,8),'VariableNames', {'Time','Faucet', 'Toilet', 'Shower', 'ClothesWasher', 'Dishwasher', 'Bathtub', 'TOTAL'});
testStatistics = array2table(zeros(0,9),'VariableNames', {'Label', 'Duration', 'Volume', 'Peak', 'Mean', 'Hour', 'EventStartTime', 'EventStartIdx', 'EventEndIdx'});
testTrajectories = array2table(zeros(0,8),'VariableNames', {'Time','Faucet', 'Toilet', 'Shower', 'ClothesWasher', 'Dishwasher', 'Bathtub', 'TOTAL'});


pb = CmdLineProgressBar('Generating Training Events...');
for i = 1:nTrainEvents
    pb.print(i, nTrainEvents);
    rng(i); % Set the random seed for reproducibility
    for appliance  = appliances
        [trainStatistics, trainTrajectories] = processEvent(appliance, database, features, HHsize, trainStatistics, trainTrajectories);
    end
end

writetable(trainStatistics, sprintf('%sTrain_statistics.csv', outputFolder));
writetable(trainTrajectories, sprintf('%sTrain_trajectory.csv', outputFolder));


pbTest = CmdLineProgressBar('Generating Test Events...');
for i = 1:nTestEvents
    pbTest.print(i, nTestEvents);
    rng(nTrainEvents+i); % Set the random seed for reproducibility
    for appliance  = appliances
        [testStatistics, testTrajectories] = processEvent(appliance, database, features, HHsize, testStatistics, testTrajectories);
    end
end

writetable(testStatistics, sprintf('%sTest_statistics.csv', outputFolder));
writetable(testTrajectories, sprintf('%sTest_trajectory.csv', outputFolder));


function [statistics, trajectories] = processEvent(appliance, database, features, HHsize, statistics, trajectories)
    [event, featName] = getEventFeatures(appliance, database.signatures, features, database, HHsize);
    trajectory = adjustEventTrajectory(event);

    % Create new statistics row
    newRow.Label = featName;
    newRow.Duration = event.duration10s * 10;
    newRow.Volume = event.volume;
    newRow.Peak = max(trajectory);
    newRow.Mean = mean(trajectory);
    newRow.EventStartTime = event.timeStartTS;
    newRow.EventStartIdx = height(trajectories) + 1;
    newRow.EventEndIdx = newRow.EventStartIdx + event.duration10s - 1;
    newRow.Hour = hours(event.timeStartTS);
    statistics = [statistics; struct2table(newRow)];

    % Create new trajectory row
    newTrajectoryTable = array2table(zeros(length(trajectory), 7), ...
        'VariableNames', {'Time','Faucet','Shower','Toilet','ClothesWasher','Dishwasher','Bathtub'});
    newTrajectoryTable.Time = event.timeStartTS + seconds(0:10:newRow.Duration-10)';
    newTrajectoryTable.(featName) = trajectory';
    newTrajectoryTable.TOTAL = trajectory';
    
    trajectories = [trajectories; newTrajectoryTable];
end

