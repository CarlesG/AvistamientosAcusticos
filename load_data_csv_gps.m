%% Script for load data from  all gps .csv files in one single variable structure.

clear all

% Data path
gps_path = 'C:/Users/MSI/AvistamientosAcusticos/DatosGPS';

% Read file name and path
files_gps = dir([gps_path filesep '*.csv']);
T_total = table();
for i = 1:length(files_gps)
    T = readtable([files_gps(i).folder filesep files_gps(i).name]);
    T_total = [T_total; T];
    %pause()
end
save TotalGPSdata.mat T_total
