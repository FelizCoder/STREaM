function [outputTrajectory, statistics] = generateConsumptionEvents(outputTrajectory, param, database, features)

% Core of STREaM (STochastic REsidential water end use Model). This function generates
% synthetic water end-use time series.

% Appliance list
appNames = fieldnames(param.appliances);

% Appliance data
signatures=database.signatures;

% Selected house dimension
HHsize = param.HHsize;

% Other parameters
second10Day = 24*360; % Number of 10-second units in a day

statistics = array2table(zeros(0,9),'VariableNames', {'Label', 'Duration', 'Volume', 'Peak', 'Mean', 'Hour', 'EventStartTime', 'EventStartIdx', 'EventEndIdx'});


for currApp = 1:length(appNames) % For each appliance
    currentAppName = appNames{currApp};
    % disp([' Generating data for ' currentAppName]);
    currentAppActive = param.appliances.(currentAppName);


    % Consumption events generation
    switch currentAppActive
        case 0 % Empty case, appliance not active
        case 1
            for dayID = 1: param.H

                % --- Step 1: Number of events per day
                numEvents = random(database.UseProbabilities.(currentAppName).NumberOfEventsPerDay{1,HHsize}{1,1});
                randomizeRound = randi(2,1);
                if randomizeRound ==1
                    numEvents = ceil(numEvents);
                else
                    numEvents = floor(numEvents);
                end

                % -- Step 2: Duration and Volume
                duration10s = zeros(1,numEvents);
                volumes = zeros(1,numEvents);
                timeStart = zeros(1,numEvents);

                for eventID = 1:numEvents

                    % --- Step 3: assign Duration, Volume and Signature
                    [event, featName] = getEventFeatures(currentAppName, signatures, features, database, HHsize);
                    duration10s(eventID) = event.duration10s;
                    volumes(eventID) = event.volume;
                    timeStart(eventID) = event.timeStart;

                    % --- Step 4: scale Signature 
                    trajectory = adjustEventTrajectory(event);

                    % Placing event in time series
                    startIDX = max(min((dayID-1)*second10Day + timeStart(eventID), length(outputTrajectory.(featName))),1);
                    endIDX = max(min((dayID-1)*second10Day + timeStart(eventID) + length(trajectory) -1, length(outputTrajectory.(featName))),1);
                    trajectory = trajectory(1:endIDX - startIDX +1);
                    outputTrajectory.(featName)(startIDX : endIDX) = ...
                        outputTrajectory.(featName)(startIDX : endIDX) + trajectory';

                    % Updating statistics
                    newRow.Label = featName;
                    newRow.Duration = event.duration10s * 10; % Duration in seconds
                    newRow.Volume = event.volume; % Volume in liters
                    newRow.Peak = max(trajectory);
                    newRow.Mean = mean(trajectory);
                    newRow.EventStartTime = outputTrajectory.Time(startIDX);
                    newRow.EventStartIdx = startIDX;
                    newRow.EventEndIdx = endIDX;
                    newRow.Hour = hours(outputTrajectory.Time(startIDX));
                    statistics = [statistics; struct2table(newRow)];

                end
            end
    end
end