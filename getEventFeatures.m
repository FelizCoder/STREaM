function [event, featName] = getEventFeatures(currentAppName, signatures, features, database, HHsize)
    % Gets the appropriate signature and feature name for a given appliance
    %
    % Inputs:
    %   currentAppName - string, name of the current appliance
    %   signatures - struct containing all signature data
    %   features - struct containing feature data
    %   database - struct containing the database of probabilities
    %   HHsize - integer, size of the household
    %
    % Outputs:
    %   event - object containing the event trajectory, duration, volume, and timeStart
    %   featName - string, name of the feature category
    
    tempTimeStart = datevec(random(database.UseProbabilities.(currentAppName).EventStartTime{1,HHsize}{1,1}));
    event.timeStartTS = duration(tempTimeStart(4:6));
    event.timeStartIdx = 360*tempTimeStart(4) + 6*tempTimeStart(5) + round(tempTimeStart(6)/10); % Event start index (10 second resolution)


    switch currentAppName
        case 'StToilet'
            randSig = randi(length(signatures.StandardToilet));
            featName = "Toilet";
            event.signature = signatures.StandardToilet{1, randSig};
        case 'HEToilet'
            randSig = randi(length(signatures.EfficientToilet));
            featName = "Toilet";
            event.signature = signatures.EfficientToilet{1, randSig};
        case 'StShower'
            randSig = randi(length(signatures.StandardShower));
            featName = "Shower";
            event.signature = signatures.StandardShower{1, randSig};
        case 'HEShower'
            randSig = randi(length(signatures.StandardShower));
            featName = "Shower";
            event.signature = signatures.StandardShower{1, randSig};
        case 'StFaucet'
            randSig = randi(length(signatures.StandardFaucet));
            featName = "Faucet";
            event.signature = signatures.StandardFaucet{1, randSig};
        case 'HEFaucet'
            randSig = randi(length(signatures.StandardFaucet));
            featName = "Faucet";
            event.signature = signatures.StandardFaucet{1, randSig};
        case 'StClothesWasher'
            randSig = randi(length(signatures.StandardClothesWasher));
            featName = "ClothesWasher";
            event.signature = signatures.StandardToilet{1, randSig};
        case 'HEClothesWasher'
            randSig = randi(length(signatures.EfficientClothesWasher));
            featName = "ClothesWasher";
            event.signature = signatures.StandardToilet{1, randSig};
        case 'StDishwasher'
            randSig = randi(length(signatures.StandardDishwasher));
            featName = "Dishwasher";
            event.signature = signatures.StandardToilet{1, randSig};
        case 'HEDishwasher'
            randSig = randi(length(signatures.StandardDishwasher));
            featName = "Dishwasher";
            event.signature = signatures.StandardToilet{1, randSig};
        case 'StBathtub'
            randSig = randi(length(signatures.Bathtub));
            featName = "Bathtub";
            event.signature = signatures.Bathtub{1, randSig};
        case 'HEBathtub'
            randSig = randi(length(signatures.Bathtub));
            featName = "Bathtub";
            event.signature = signatures.Bathtub{1, randSig};
    end

    randFeat = randi(height(features.(featName)));
    event.duration10s = round(features.(featName).Duration(randFeat) / 10);
    event.volume = features.(featName).Volume(randFeat);


end