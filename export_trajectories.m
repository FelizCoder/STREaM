%% ::: LOADING COMPLETE DATABASE :::
homeFolder = pwd;
addpath([homeFolder '/_DATA']); % Path to the folder where the database.mat file is stored
load database.mat

database.signatures
