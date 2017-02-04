[FileName,SavePath,FilterIndex] = uigetfile({'*.avi'},'Choose a movie file');
if isequal(FileName,0)
    return
end
DataName = FileName;
[~,DataName,~] = fileparts(DataName);
% get all files with the same extension
PathName = [SavePath 'frames/'];
FileName = '00001.jpg';
[prefix,junk,ext]=fileparts(FileName);
FileList=dir([PathName ['*' ext]]);
imshow([PathName FileList(1).name]);

%% Step 0: Calculate coefficients based on image brightness and contrast
max_speed = 25;
min_speed = 2; 
max_bw = 130;
min_bw = 50;
%max_dist = 80;
max_dist = 80;
min_dist = 40;
max_cluster = 15;
max_area = Inf;
min_area = 5;
max_histeresis = 8;
max_smooth = 9;
StartHour = 6;
StartMinute = 31;
StartSecond = 11.5;
StartTime = StartHour*3600 + StartMinute*60 + StartSecond;
[im_mean, im_std, coeff_bw, coeff_speed,...
 coeff_dist, coeff_cluster, coeff_arealim,...
 coeff_hysteresis,coeff_smooth] = CalculateCoefficients(...
                    PathName, FileList, ...
                    max_speed,min_speed, ...
                    max_bw, min_bw, ...
                    max_dist,min_dist, ...
                    max_cluster, max_area, min_area, ...
                    max_histeresis, max_smooth);

%% Step 1: Detect and filter blobs
[xy_blob, area_blob] = BlobDetector(PathName, FileList, coeff_bw,...
                                    coeff_arealim, coeff_cluster, 0);                              
% Step 2: Assign Object IDs
[xy_obj, obj_length] = AssignObjects(PathName, FileList, xy_blob, coeff_speed, coeff_dist, coeff_smooth, 0);
xy_obj_temp = xy_obj;
ind_obj_temp = obj_length;

% Step 3: Smoothing Object Trajectories
[xy_obj, obj_length] = SmoothPaths(xy_obj,obj_length, coeff_smooth);

% Step 4: Calculate State Transitions
[state_log] = CalculateState(xy_obj,obj_length,coeff_hysteresis,100);

% Step 5: Clean Up Non State Transition Objects
[xy_obj, obj_length, state_log] = CleanUpObjects(xy_obj,obj_length,state_log,coeff_hysteresis);
state_log_temp = state_log;

% Step 6: Plot States
PlotStates(state_log);

% Step 7: Save and Write data
save([SavePath DataName '_giant.mat'],'xy_blob','xy_obj',...
    'state_log','obj_length','im_mean','im_std',...
    'coeff_dist','coeff_speed','coeff_bw','coeff_cluster',...
    'coeff_hysteresis', 'coeff_arealim','coeff_smooth',...
    'StartHour','StartMinute','StartSecond','StartTime');
fID = fopen([SavePath DataName '_statechange.csv'],'w');
fprintf(fID,'%s,%s,%s\n','objID','time','direction');
for ii = 1:size(state_log,2)
    fprintf(fID,'%d,%d:%d:%d,%d\n',state_log(1,ii),...
        floor(state_log(2,ii)/3600),...
        mod(floor(state_log(2,ii)/60),60),...
        mod(floor(state_log(2,ii)),60), state_log(3,ii));
end
fclose(fID);
fID = fopen([SavePath DataName '_statechange_realtime.csv'],'w');
fprintf(fID,'%s,%s,%s\n','objID','time','direction');
for ii = 1:size(state_log,2)
    fprintf(fID,'%d,%d:%d:%d,%d\n',state_log(1,ii),...
        floor((state_log(2,ii)*3/29.97 + StartTime)/3600),...
        mod(floor((state_log(2,ii)*3/29.97 + StartTime)/60),60),...
        mod(floor((state_log(2,ii)*3/29.97 + StartTime)),60), state_log(3,ii));
end
fclose(fID);

%% plot and draw
PlotObjects(PathName, FileList, xy_obj, obj_length, xy_blob,...
                state_log, 1,numel(FileList),StartTime,0);      