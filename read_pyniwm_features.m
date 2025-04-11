%% Read Pyniwm Statistics
dataset = readtable("<your path>");
%% Find unique End Uses
dataset = dataset(:, ["Duration","Volume","SumAs"]);
endUses = unique(dataset.SumAs);

for i = 1:length(endUses)
    endUse = string(endUses(i));
    % Find all rows with the same end use
    features.(endUse) = dataset(dataset.SumAs == endUse, ["Duration","Volume"]);
end
%% Save Statistics to a .mat file
save("_DATA/pyniwm_features.mat", "features")