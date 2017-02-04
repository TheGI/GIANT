PathName = uigetdir;
PathName = [PathName '/'];
FileList = dir([PathName '*0.AVI']);
datainfo = struct(...
    'date', {}, ...
    'colonyid', {}, ...
    'exptype', {},...
    'videonum',{},...
    'trailnum', {},...
    'starthour', {},...
    'startminute',{},...
    'startsecond',{},...
    'fullname', {});
antinfo = struct('im_mean',{},'im_std',{},...
    'xy_blob',{},'xy_obj',{},'state_log',{},'obj_length',{},...
    'coeff_dist',{},'coeff_speed',{},'coeff_bw',{},...
    'coeff_cluster',{},'coeff_hysteresis',{},...
    'coeff_arealim',{},'coeff_smooth',{},'coeff_antsize',{},...
    'StartHour',{},'StartMinute',{},'StartSecond',{},'StartTime',{});

for ii = 1:numel(FileList)
    NameParts = strsplit(FileList(ii).name,{'_','.'});
    datainfo(ii).date = NameParts{1};
    datainfo(ii).colonyid = NameParts{2};
    datainfo(ii).exptype = NameParts{3};
    datainfo(ii).videonum = NameParts{4};
    datainfo(ii).trailnum = NameParts{5};
    datainfo(ii).starthour = NameParts{6};
    datainfo(ii).startminute = NameParts{7};
    datainfo(ii).startsecond = NameParts{8};
    [~, datainfo(ii).fullname, ~] = fileparts(FileList(ii).name);
end
%%
for ii = 1:length(datainfo)
ImagePathName{ii} = [PathName datainfo(ii).fullname '/'];
ImageFileList{ii} = dir([ImagePathName{ii} ['*.jpg']]);

% Step 0: Calculate Image Contrast and Brightness
[antinfo(ii).im_mean, antinfo(ii).im_std] = CalculateImageStatistics(ImagePathName{ii}, ImageFileList{ii});

% Step 0: Calculate Coefficients
max_speed = 25; min_speed = 2; 
%max_bw = 130; min_bw = 80;
max_bw = 100; min_bw = 80;
max_dist = 80; min_dist = 40;
max_cluster = 15; max_area = Inf; max_antsize = 50;
min_area = 7; max_histeresis = 8; max_smooth = 9; 
% This is for D19
% max_dist = 80; min_dist = 40;
% max_cluster = 15; max_area = Inf; max_antsize = 50;
% min_area = 7; max_histeresis = 8; max_smooth = 9; 
% max_dist = 120; min_dist = 60;
% max_cluster = 40; max_area = Inf; max_antsize = 80;
% min_area = 30; max_histeresis = 8; max_smooth = 9; 
antinfo(ii).StartHour = str2num(datainfo(ii).starthour);
antinfo(ii).StartMinute = str2num(datainfo(ii).startminute);
antinfo(ii).StartSecond = str2num(datainfo(ii).startsecond);
antinfo(ii).StartTime = antinfo(ii).StartHour*3600 + ...
    antinfo(ii).StartMinute*60 + antinfo(ii).StartSecond;

[antinfo(ii).coeff_bw, ...
 antinfo(ii).coeff_speed,...
 antinfo(ii).coeff_dist, ...
 antinfo(ii).coeff_cluster, ...
 antinfo(ii).coeff_arealim,...
 antinfo(ii).coeff_hysteresis,...
 antinfo(ii).coeff_smooth,...
 antinfo(ii).coeff_antsize] = ...
 CalculateCoefficients(...
    antinfo(ii).im_mean,...
    antinfo(ii).im_std,...
    max_speed,min_speed,...
    max_bw, min_bw, ...
    max_dist,min_dist, ...
    max_cluster, max_area, min_area, ...
    max_histeresis,max_smooth,max_antsize);

% Step 1: Detect and filter blobs
[antinfo(ii).xy_blob] = ...
 BlobDetector(...
    ImagePathName{ii}, ...
    ImageFileList{ii},...
    antinfo(ii).coeff_bw,...
    antinfo(ii).coeff_arealim,...
    antinfo(ii).coeff_cluster, 0);   

% Step 2: Assign Object IDs
[antinfo(ii).xy_obj, ...
 antinfo(ii).obj_length] = ...
 AssignObjects(...
    ImagePathName{ii}, ...
    ImageFileList{ii},...
    antinfo(ii).xy_blob, ...
    antinfo(ii).coeff_speed, ...
    antinfo(ii).coeff_dist,...
    antinfo(ii).coeff_smooth,...
    antinfo(ii).coeff_antsize, 0);
xy_obj_temp = antinfo(ii).xy_obj;
ind_obj_temp = antinfo(ii).obj_length;

% Step 3: Smoothing Object Trajectories
[antinfo(ii).xy_obj, ...
 antinfo(ii).obj_length] = ...
 SmoothPaths(...
    antinfo(ii).xy_obj,...
    antinfo(ii).obj_length,...
    antinfo(ii).coeff_smooth);

% Step 4: Calculate State Transitions
[antinfo(ii).state_log] = ...
 CalculateState(...
    antinfo(ii).xy_obj,antinfo(ii).obj_length,...
    antinfo(ii).coeff_hysteresis);

% Step 5: Clean Up Non State Transition Objects
[antinfo(ii).xy_obj, ...
 antinfo(ii).obj_length, ...
 antinfo(ii).state_log] = ...
CleanUpObjects(...
    antinfo(ii).xy_obj,...
    antinfo(ii).obj_length,...
    antinfo(ii).state_log,...
    antinfo(ii).coeff_hysteresis);
state_log_temp = antinfo(ii).state_log;

% Step 6: Plot States
figure;
PlotStates(antinfo(ii).state_log,20);
title(datainfo(ii).fullname);

% Step 7: Save and Write data
save([PathName datainfo(ii).fullname '_giant.mat'],'antinfo');
fID = fopen([PathName datainfo(ii).fullname '_giant.csv'],'w');
fprintf(fID,'%s,%s,%s\n','objID','time','direction');
for jj = 1:size(antinfo(ii).state_log,2)
    fprintf(fID,'%d,%d:%d:%d,%d\n',antinfo(ii).state_log(1,jj),...
        floor(antinfo(ii).state_log(2,jj)*3/29.97/3600),...
        mod(floor(antinfo(ii).state_log(2,jj)*3/29.97/60),60),...
        mod(floor(antinfo(ii).state_log(2,jj)*3/29.97),60), ...
        antinfo(ii).state_log(3,jj));
end
fclose(fID);
fID = fopen([PathName datainfo(ii).fullname '_giant_realtime.csv'],'w');
fprintf(fID,'%s,%s,%s\n','objID','time','direction');
for jj = 1:size(antinfo(ii).state_log,2)
    fprintf(fID,'%d,%d:%d:%d,%d\n',antinfo(ii).state_log(1,jj),...
        floor((antinfo(ii).state_log(2,jj)*3/29.97 + antinfo(ii).StartTime)/3600),...
        mod(floor((antinfo(ii).state_log(2,jj)*3/29.97 + antinfo(ii).StartTime)/60),60),...
        mod(floor((antinfo(ii).state_log(2,jj)*3/29.97 + antinfo(ii).StartTime)),60),...
        antinfo(ii).state_log(3,jj));
end
fclose(fID);
end

state_log = [];
for ii = 1:size(antinfo,2)
    state_log_temp = antinfo(ii).state_log;
    state_log_temp(2,:) = state_log_temp(2,:)*3/29.97 + antinfo(ii).StartTime;
    state_log = cat(2,state_log, state_log_temp); 

end
save([PathName datainfo(1).date '_' datainfo(1).colonyid '_giant.mat'],'antinfo','state_log');
fID = fopen([PathName datainfo(1).date '_' datainfo(1).colonyid '_giant_all.csv'],'w');
fprintf(fID,'%s,%s\n','time','direction(left2right=1 | right2left=2)');
for jj = 1:size(state_log,2)
    fprintf(fID,'%d:%d:%d,%d\n',...
        floor(state_log(2,jj)/3600),...
        mod(floor(state_log(2,jj)/60),60),...
        mod(floor(state_log(2,jj)),60), ...
        state_log(3,jj));
end
figure;
PlotStates(state_log,100);
%% plot and draw
filenum = 1;
startframe = 15000;
endframe = numel(ImageFileList{filenum});
objORblob = 0;
PlotObjects(ImagePathName{filenum}, ...
            ImageFileList{filenum}, ...
            antinfo(filenum).xy_obj, ...
            antinfo(filenum).obj_length,...
            antinfo(filenum).xy_blob,...
            antinfo(filenum).state_log,...
            startframe,endframe,...
            antinfo(filenum).StartTime,objORblob);      