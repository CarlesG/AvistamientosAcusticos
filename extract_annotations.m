%% Script for load data from manual_annotation files
clear all, close all

%% Load data from manual annotations 
%----------------------------------------------------------------------------------------
% Data path for .csv
annotation_path = 'C:/Users/MSI/AvistamientosAcusticos/AnotacionesManuales/';
files_annotated = dir([annotation_path filesep '*.csv']);

% Process to read .csv and insert in the general table de date and hour
T_annotations = table();

for i = 1:length(files_annotated)
       % Reading the csv information
       T = readtable([files_annotated(i).folder filesep files_annotated(i).name],'DecimalSeparator',','); 
 
       filename = T.filename;
       date = cellfun(@(x) x(9:end-4), filename, 'UniformOutput', false);

       % Pass the data to timetable class
       time_stamp = datetime(date, 'InputFormat', 'yyyyMMdd_HHmmss', 'Format', 'dd-MMM-uuuu HH:mm:ss.SSS');

       % Adding the seconds of the initial event
       time_stamp = time_stamp + seconds(T.tini);
       T = addvars(T, time_stamp, 'Before', "filename");
       T = removevars(T, ["user", "date_time_annotation"]);

       % Order the table by date with the variable time_stamp of the table
       T = sortrows(T,'time_stamp');
       T_annotations = [T_annotations;T];
       %^head(T, 5)
end
% Order the table by date column
T_annotations = sortrows(T_annotations, 'time_stamp');

% Adding new columns to the total annotations table
line = repmat("OFF", size(T_annotations, 1), 1); 
% line = NaN(size(T_annotations,1), 1);
lat_boat = NaN(size(T_annotations, 1), 1);
lon_boat = NaN(size(T_annotations, 1), 1);
Region.label = repmat("Mazarron", size(T_annotations, 1), 1);
T_annotations = addvars(T_annotations, Region.label, line, 'After', "time_stamp", 'NewVariableNames', {'Region.label', 'line'});
T_annotations = addvars(T_annotations, lat_boat, lon_boat, 'After', "freqmax");

%head(T_annotations, 5)

%% Interpolation of Latitude and Longitud 
%--------------------------------------------------------------------------------  
% Loading GPS data

gps_path = 'C:/Users/MSI/AvistamientosAcusticos/DatosGPS';
files_gps = dir([gps_path filesep '*.csv']);
T_gps = table();
T  = table();

for i = 1:length(files_gps)
    T = readtable([files_gps(i).folder filesep files_gps(i).name]);
    T_gps = [T_gps; T];
    %pause()
end

t_gps = T_gps.UTC;
lat = T_gps.Latitude;
lon = T_gps.Longitude;
t_events = T_annotations.time_stamp;


for i = 1:length(t_events)
    
    marg = 10;
    idx = find((t_events(i) - seconds(marg) <= t_gps) & (t_gps  <= t_events(i) + seconds(marg)));
    if isempty(idx)
       continue
    end

    % for represent data for each interpolated interval
    %geobasemap grayland % to represent data for each interpolated interval
    %figure(1), geoplot(lat(idx),lon(idx), 'bo'), hold on

    % Linear interpolation process
    time_p = t_gps(idx(1)):seconds(0.001):t_gps(idx(end));
    table_time = timetable(t_gps(idx), lat(idx), lon(idx),'VariableNames',{'lat','lon'});

    if sum(diff(table_time.Time) == 0)
        duplicate = (diff(table_time.Time) == 0);
        idx_duplicate = find(duplicate == 1);
        table_time(idx_duplicate,:) = [];
    end
    table_interp = retime(unique(table_time), time_p, 'linear');
    
    %% Finding near time for the event
    [~, idx_min] = min(abs(table_interp.Time - t_events(i)));
    
    % To represent the interpolated and the selected final point
    %figure(1), geoplot(table_interp.lat, table_interp.lon, 'r.')
    %figure(1), geoplot(table_interp.lat(idx_min), table_interp.lon(idx_min),'g*','MarkerSize',14)
    %legend({'original data','interpolated data','selected point'})
    %text(table_interp.lat(idx_min), table_interp.lon(idx_min), num2str(i),'FontSize',14)
    %text(table_interp.lat(idx_min), table_interp.lon(idx_min), [num2str(i) T_annotations.m_event_type(i)],'FontSize',14)

    % Saving latitude and longitude in the table of the annotation
    T_annotations.lat_boat(i) = table_interp.lat(idx_min);
    T_annotations.lon_boat(i) = table_interp.lon(idx_min);
    disp(['Event ' num2str(i)])
    %pause()
end

%% Fulling table with GPS tracking by garmin GPS
%-------------------------------------------------------------------------------- 


%% Introduction of transects information by time
% To determinate the transect of each entry of the annotation table
%--------------------------------------------------------------------------------   

transect_path = 'C:\Users\MSI\AvistamientosAcusticos\DatosTransectos';
files_transects = dir([transect_path filesep '*.xlsx']);
T_transects = table();

for i = 1:length(files_transects)
   T_aux = readtable([files_transects(i).folder filesep files_transects(i).name]);
   T_aux.id = num2cell(T_aux.id);
   time_stamp_ini = T_aux.date + days(T_aux.startTime);
   time_stamp_end = T_aux.date + days(T_aux.endTime);
   time_stamp_ini.Format = 'dd-MMM-yyyy HH:mm:ss.SSS';
   time_stamp_end.Format = 'dd-MMM-yyyy HH:mm:ss.SSS';
   T_aux = addvars(T_aux,time_stamp_ini,'Before','date');
   T_aux = addvars(T_aux,time_stamp_end,'Before','date');
   T_transects  = [T_transects; T_aux];
end

for i = 1:size(T_transects,1)
    idx_line = find((t_events >= T_transects.time_stamp_ini(i)) & (t_events <= T_transects.time_stamp_end(i)));
    if ~isempty(idx_line)
       T_annotations.line(idx_line) = T_transects.id(i); 
    end
    %pause()
end

% Saving the annotated tables
save Extract_data.mat T_annotations T_gps T_transects
