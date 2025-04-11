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

statistics = array2table(zeros(0,4),'VariableNames', {'Label', 'Duration', 'Volume', 'EventStartTime'});


for currApp = 1:length(appNames) % For each appliance
    currentAppName = appNames{currApp};
    disp([' Generating data for ' currentAppName]);
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
                durations = zeros(1,numEvents);
                volumes = zeros(1,numEvents);
                timeStart = zeros(1,numEvents);

                for eventID = 1:numEvents
                    % --- Step 3: Time of day
                    tempTimeStart = datevec(random(database.UseProbabilities.(currentAppName).EventStartTime{1,HHsize}{1,1}));
                    timeStart(eventID) = 360*tempTimeStart(4) + 6*tempTimeStart(5) + round(tempTimeStart(6)/10); % Event start index (10 second resolution)

                    % --- Step 4: assign Duration, Volume and Signature
                    switch currentAppName
                        case 'StToilet'
                            randSig = randi(length(signatures.StandardToilet));
                            featName = "Toilet";
                            event = signatures.StandardToilet{1, randSig};
                        case 'HEToilet'
                            randSig = randi(length(signatures.EfficientToilet));
                            featName = "Toilet";
                            event = signatures.EfficientToilet{1, randSig};
                        case 'StShower'
                            randSig = randi(length(signatures.StandardShower));
                            featName = "Shower";
                            event = signatures.StandardShower{1, randSig};
                        case 'HEShower'
                            randSig = randi(length(signatures.StandardShower));
                            featName = "Shower";
                            event = signatures.StandardShower{1, randSig};
                        case 'StFaucet'
                            randSig = randi(length(signatures.StandardFaucet));
                            featName = "Faucet";
                            event = signatures.StandardFaucet{1, randSig};
                        case 'HEFaucet'
                            randSig = randi(length(signatures.StandardFaucet));
                            featName = "Faucet";
                            event = signatures.StandardFaucet{1, randSig};
                        case 'StClothesWasher'
                            randSig = randi(length(signatures.StandardClothesWasher));
                            featName = "Clotheswasher";
                            event = signatures.StandardClothesWasher{1, randSig};
                        case 'HEClothesWasher'
                            randSig = randi(length(signatures.EfficientClothesWasher));
                            featName = "Clotheswasher";
                            event = signatures.EfficientClothesWasher{1, randSig};
                        case 'StDishwasher'
                            randSig = randi(length(signatures.StandardDishwasher));
                            featName = "Dishwasher";
                            event = signatures.StandardDishwasher{1, randSig};
                        case 'HEDishwasher'
                            randSig = randi(length(signatures.StandardDishwasher));
                            featName = "Dishwasher";
                            event = signatures.StandardDishwasher{1, randSig};
                        case 'StBathtub'
                            randSig = randi(length(signatures.Bathtub));
                            featName = "Bathtub";
                            event = signatures.Bathtub{1, randSig};
                        case 'HEBathtub'
                            randSig = randi(length(signatures.Bathtub));
                            featName = "Bathtub";
                            event = signatures.Bathtub{1, randSig};
                    end

                    randFeat = randi(height(features.(featName)));
                    durations(eventID) = features.(featName).Duration(randFeat);
                    volumes(eventID) = features.(featName).Volume(randFeat);

                    event = event(2:end-1);

                    posPositions = find(event>0);
                    % Resizing signature length
                    while length(posPositions) > durations(eventID)
                        position=randi(length(posPositions),1);
                        event(posPositions(position)) = [];
                        posPositions = find(event>0);
                    end

                    while length(posPositions) < durations(eventID)
                        position=randi(length(posPositions),1);
                        event = [event(1:posPositions(position)), event(posPositions(position):end)];
                        posPositions = find(event>0);
                    end

                    % Resizing signature volume
                    eventVolume = sum(event);

                    volumeDifference = eventVolume - volumes(eventID);

                    if volumeDifference > 0 % Signature should be lowered
                        coeffProp = event./eventVolume;
                        coeffProp(isnan(coeffProp)) = 0;
                    else % Signature should be increased
                        coeffProp = (event>0)/length(posPositions);
                        coeffProp(isnan(coeffProp)) = 0;
                    end

                    event = event - volumeDifference.*coeffProp;
                    if sum((event<0))> 0
                        disp('error');
                    end

                    % Placing event in time series
                    startIDX = max(min((dayID-1)*second10Day + timeStart(eventID), length(outputTrajectory.(featName))),1);
                    endIDX = max(min((dayID-1)*second10Day + timeStart(eventID) + length(event) -1, length(outputTrajectory.(featName))),1);
                    event = event(1:endIDX - startIDX +1);
                    outputTrajectory.(featName)(startIDX : endIDX) = ...
                        outputTrajectory.(featName)(startIDX : endIDX) + event';

                    % Updating statistics
                    newRow.Label = featName;
                    newRow.Duration = durations(eventID);
                    newRow.Volume = volumes(eventID);
                    newRow.EventStartTime = outputTrajectory.Time(startIDX);
                    statistics = [statistics; struct2table(newRow)];

                end
            end
    end
end