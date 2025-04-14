outputFolder = './output/';
nHouses = 1000; % Number of days to simulate

pb = CmdLineProgressBar('Generating data...');
for i = 1:nHouses
    pb.print(i, nHouses);
    MAIN_STREaM
    outputTrajectoryTable = struct2table(outputTrajectory);
    writetable(outputTrajectoryTable, sprintf('%sHouse_%d_10s_trajectory.csv', outputFolder, i))
    writetable(statistics, sprintf('%sHouse_%d_10s_statistics.csv', outputFolder, i))
end

