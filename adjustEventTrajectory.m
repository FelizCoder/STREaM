function [trajectory] = adjustEventTrajectory(event)
    % Adjusts the event trajectory by scaling duration and volume
    %
    % Inputs:
    %   features - struct containing feature data
    %
    % Outputs:
    %   trajectory - adjusted trajectory scaled to L/min
        
    % Remove edge values
    trajectory = event.signature(2:end-1);
    
    % Resize signature length
    posPositions = find(trajectory>0);
    while length(posPositions) > event.duration10s
        position = randi(length(posPositions),1);
        trajectory(posPositions(position)) = [];
        posPositions = find(trajectory>0);
    end
    
    while length(posPositions) < event.duration10s
        position = randi(length(posPositions),1);
        trajectory = [trajectory(1:posPositions(position)), trajectory(posPositions(position):end)];
        posPositions = find(trajectory>0);
    end
    
    % Resize signature volume
    eventVolume = sum(trajectory);
    volumeDifference = eventVolume - event.volume;
    
    if volumeDifference > 0 % Signature should be lowered
        coeffProp = trajectory./eventVolume;
    else % Signature should be increased
        coeffProp = (trajectory>0)/length(posPositions);
    end
    coeffProp(isnan(coeffProp)) = 0;
    
    % Adjust trajectory volume
    trajectory = trajectory - volumeDifference.*coeffProp;
    
    % Check for negative values
    if sum(trajectory<0) > 0
        warning('Negative values detected in trajectory');
    end
    
    % Scale to L/min
    trajectory = trajectory * 6;
end