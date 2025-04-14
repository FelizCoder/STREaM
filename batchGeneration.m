outputFolder = './output/';

nDays = 1400; % Number of days to simulate

for i = 1:nDays
    fprintf('Generating data: %d/%d [%.1f%%]\r', i, nDays, (i/nDays)*100);
    MAIN_STREaM
    outputTrajectoryTable = struct2table(outputTrajectory);
    writetable(outputTrajectoryTable, sprintf('%sDay_%d_10s_trajectory.csv', outputFolder, i))
    writetable(statistics, sprintf('%sDay_%d_10s_statistics.csv', outputFolder, i))
end
fprintf('\n'); % Add new line at the end

