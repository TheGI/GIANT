function [xy_obj, obj_length] = AssignObjects(PathName, FileList, xy_blob, coeff_speed, coeff_dist, coeff_smooth,coeff_antsize, debug)
xy_obj = [];
obj_length = [];
time_bomb = struct('id', {},'timeleft', {},'starttime', {});
d = imread([PathName FileList(1).name]);
image_x = size(d,2);
image_y = size(d,1);
impossiblebox = [coeff_antsize, coeff_antsize;....
    coeff_antsize, image_y-coeff_antsize;....
    image_x-coeff_antsize, image_y-coeff_antsize;...
    image_x-coeff_antsize,coeff_antsize];

for tt = 1:size(xy_blob,1)
    % Step 1: Find all id of active objects and blobs
    blob_active = find(xy_blob(tt,:,1)~=0);
    num_blob_active = length(blob_active);
    obj_active = [time_bomb([time_bomb(:).starttime] < tt).id];
    num_obj_active = length(obj_active);
    
    % Step 2: If there is no active object but active blobs assign these
    % blobs to new objects
    if num_obj_active == 0
        if num_blob_active > 0
            for ii = 1:length(blob_active)
                bb = blob_active(ii);
                blob_x = xy_blob(tt,bb,1);
                blob_y = xy_blob(tt,bb,2);
                
                xy_obj(end+1,1,1:3) = [blob_x blob_y tt];
                obj_length(end+1) = 1;
                time_bomb(end+1).id = length(obj_length);
                time_bomb(end).timeleft = coeff_speed(tt)+1;
                time_bomb(end).starttime = tt;
            end
        end
    else
        % Step 3: Get current position and previous position of all active
        % objects
        obj_curpos = [];
        obj_prevpos = [];
        obj_nextpos = [];
        obj_initpos = [];
        for ii = 1:length(obj_active)
            oo = obj_active(ii);
            obj_curpos(ii,:) = xy_obj(oo, obj_length(oo), 1:2);
            if obj_length(oo) > 1 && obj_length(oo) <= 3
                obj_prevpos(ii,:) = xy_obj(oo, obj_length(oo)-1, 1:2);
                obj_initpos(ii,:) = xy_obj(oo, 1, 1:2);
            elseif obj_length(oo) > 3
                obj_prevpos(ii,:) = xy_obj(oo, obj_length(oo)-1, 1:2);
                obj_initpos(ii,:) = xy_obj(oo, obj_length(oo)-3, 1:2);
            else
                obj_prevpos(ii,:) = obj_curpos(ii,:);
                obj_initpos(ii,:) = obj_curpos(ii,:);
            end
        end
        
        % Step 4: Calculate object's normalized direction, velocity,
        % estimated positions in the next frame. If the estimated direction
        % of the current frame deviates more than 90 degrees from the
        % object's direction since its initial position, than search for
        % the next blob from the current position, otherwise search for the
        % next blob from the estimated position.
        obj_direction = obj_curpos - obj_initpos;
        for ii = 1:size(obj_direction,1)
            obj_direction(ii,:) = obj_direction(ii,:)/norm(obj_direction(ii,:),2);
            if isnan(obj_direction(ii,1)) || isnan(obj_direction(ii,2))
                obj_direction(ii,:) = [0 0];
            end
        end
        obj_velocity = obj_curpos - obj_prevpos;
        obj_nextpos = obj_curpos + obj_velocity;
        obj_estimate_direction = obj_curpos - obj_initpos;
        for ii = 1:size(obj_estimate_direction,1)
            obj_estimate_direction(ii,:) = obj_estimate_direction(ii,:)/norm(obj_estimate_direction(ii,:),2);
            if isnan(obj_estimate_direction(ii,1)) || isnan(obj_estimate_direction(ii,2))
                obj_estimate_direction(ii,:) = [0,0];
            end
        end
        for ii = 1:size(obj_velocity,1)
            obj_velocity(ii,:) = obj_velocity(ii,:)/norm(obj_velocity(ii,:));
            if isnan(obj_velocity(ii,1)) || isnan(obj_velocity(ii,2))
                obj_velocity(ii,:) = [0 ,0];
            end
        end
        obj_pos_to_use = [];
        for ii = 1:size(obj_velocity)
            if abs(acos(obj_velocity(ii,:)*obj_estimate_direction(ii,:)')) > pi/2
                    obj_pos_to_use(ii,:) = obj_curpos(ii,:);
            else
                obj_pos_to_use(ii,:) = obj_nextpos(ii,:);
            end
        end
        
        % Step 5: Perform knnsearch between active objects and active blobs
        % and find the best match between these objects and blobs. If there
        % are more blobs than objects, than find among the not-matched
        % blobs that are possibly the new object appearing in the scene If
        % there are more objects than blobs, unassigned objects will wait
        % for coeffcient of wait duration, which is calculated by image
        % brightness and contrast
        blob_pos = reshape(xy_blob(tt,blob_active,:),[num_blob_active,2]);
        if num_blob_active > 0
            [ind_knn,dist_knn] = knnsearch(obj_pos_to_use,blob_pos,'K',num_blob_active);
            uni_ind_knn = unique(ind_knn(:,1));
            num_uni_ind_knn = histc(ind_knn(:,1),uni_ind_knn);
            uni_ind_knn_single = uni_ind_knn(num_uni_ind_knn == 1);
            uni_ind_knn_multiple = uni_ind_knn(num_uni_ind_knn > 1);
            
            obj_match = [];
            for ii = 1:length(uni_ind_knn_single)
                bb = find(ind_knn(:,1) == uni_ind_knn_single(ii));
                % obj_active(ind_obj_possible) is oo
                ind_obj_possible = [];
                for jj = 1:size(dist_knn,2)
                    oo = obj_active(ind_knn(bb,jj));
                    if obj_length(oo) == 1
                        if sum(dist_knn(bb,jj) < max(coeff_dist))
                        ind_obj_possible(end+1) = ind_knn(bb,dist_knn(bb,jj) < max(coeff_dist));
                        end
                    else
                        if sum(dist_knn(bb,jj) < coeff_dist(tt))
                        ind_obj_possible(end+1) = ind_knn(bb,dist_knn(bb,jj) < coeff_dist(tt));
                        end
                    end
                end
                
                if ~isempty(ind_obj_possible)
                    blob_obj_angles = [];
                    for jj = 1:length(ind_obj_possible)
                        ind_oo = ind_obj_possible(jj);
                        oo = obj_active(ind_oo);
                        blob_obj_vector = blob_pos(bb,:) - obj_curpos(ind_oo,:);
                        blob_obj_vector = blob_obj_vector/norm(blob_obj_vector);
                        blob_obj_angles(end+1) = acos(obj_direction(ind_oo,:)*blob_obj_vector');
                    end
                    
                    blob_obj_angles = abs(blob_obj_angles);
                    [~,kk] = min(blob_obj_angles);
                    ind_oo = ind_obj_possible(kk);
                    oo = obj_active(ind_oo);
                    if xy_obj(oo,obj_length(oo),3) ~= tt
                        xy_obj(oo,obj_length(oo)+1,1:3) = [reshape(xy_blob(tt,bb,:),[1 2]) tt];
                        obj_length(oo) = obj_length(oo)+1;
                        ind_time_bomb = find([time_bomb(:).id] == oo);
                        time_bomb(ind_time_bomb).timeleft = coeff_speed(tt)+1;
                        time_bomb(ind_time_bomb).starttime = tt;
                        obj_match(end+1) = oo;
                    end
                end
            end
            
            blob_match = [];
            for ii = 1:length(uni_ind_knn_multiple);
                ind_blob_possible = find(ind_knn(:,1) == uni_ind_knn_multiple(ii));
                [~,kk] = min(dist_knn(ind_blob_possible,1));
                bb = ind_blob_possible(kk);
                ind_oo = uni_ind_knn_multiple(ii);
                oo = obj_active(ind_oo);
                if xy_obj(oo,obj_length(oo),3) ~= tt
                    xy_obj(oo,obj_length(oo)+1,1:3) = [reshape(xy_blob(tt,bb,:),[1 2]) tt];
                    obj_length(oo) = obj_length(oo)+1;
                    ind_time_bomb = find([time_bomb(:).id] == oo);
                    time_bomb(ind_time_bomb).timeleft = coeff_speed(tt)+1;
                    time_bomb(ind_time_bomb).starttime = tt;
                    blob_match(end+1) = bb;
                end
            end
            
            blob_nomatch_temp = setdiff(blob_active, blob_match);
            blob_nomatch = [];
            for ii = 1:length(blob_nomatch_temp)
                bb = blob_nomatch_temp(ii);
                if sum(dist_knn(bb,:) < coeff_antsize)
                    
                else
                    blob_nomatch(end+1) = bb;
                end
            end
            
            % Step 6: For those blobs, that are not near the current
            % objects, search for blobs that appear at the boundary of the
            % scene because objects cannot appear suddenly from the middle
            % of the scene
            
            for ii = 1:length(blob_nomatch);
                bb = blob_nomatch(ii);
                blob_x = xy_blob(tt,bb,1);
                blob_y = xy_blob(tt,bb,2);
                foundmatch = inpolygon(blob_x,blob_y,impossiblebox(:,1),impossiblebox(:,2));
                if ~foundmatch
                    xy_obj(end+1,1,1:3) = [reshape(xy_blob(tt,bb,:),[1 2]) tt];
                    obj_length(end+1) = 1;
                    time_bomb(end+1).id = length(obj_length);
                    time_bomb(end).timeleft = coeff_speed(tt)+1;
                    time_bomb(end).starttime = tt;
                end
            end
            if debug
                disp(['Frame Number: ' num2str(tt)]);
                disp('Active Objects: ');
                disp(obj_active);
                disp('Object Positions: ');
                disp(obj_curpos);
                disp('Object Estimated Position ');
                disp(obj_nextpos);
                disp('Object Velocities: ');
                disp(obj_velocity);
                disp('Object Esimated Vector: ');
                disp(obj_estimate_direction);
                disp('Object Property Used: ');
                disp(obj_pos_to_use);
                disp('Active Blobs: ');
                disp(blob_active);
                disp('Blob Positions: ');
                disp(blob_pos);
                disp('Knn Matches: ');
                disp(ind_knn);
                disp('Knn Distances: ');
                disp(dist_knn);
                disp('Coeff_Dist: ');
                disp(coeff_dist(tt));
                
                disp('Blob-Object Angle: ');
                disp(abs(acos(obj_velocity*obj_estimate_direction')));
                
                d = imread([PathName FileList(tt).name]);
                imshow(d);
                hold on;
                plot(obj_curpos(:,1),obj_curpos(:,2),'ro');
                plot(obj_nextpos(:,1),obj_nextpos(:,2),'g^');
                plot(blob_pos(:,1),blob_pos(:,2),'b*');
                hold off;
                drawnow;
            end
        end
        
        % Step 7: For all new objects younger than 0.3 seconds, if these
        % objects were only detected once in the past 0.3 seconds, delete
        % them because they are likely to be noise.
        ind_time_bomb = find((tt - [time_bomb(:).starttime]) < 3 &...
                             (tt - [time_bomb(:).starttime]) > 1);
        newobj_inactive = [time_bomb(ind_time_bomb).id];
        for ii = 1:length(newobj_inactive)
            oo = newobj_inactive(ii);
            if obj_length(oo) == 1
                time_bomb([time_bomb(:).id] == oo).timeleft = 0;
            end
        end
        
        % Step 8: If the object's estimated position is out of the scene,
        % then delete these objects since they moved out of the scene
        ind_obj_outofbox = find(obj_nextpos(:,1) < 0 | ...
            obj_nextpos(:,1) > image_x |...
            obj_nextpos(:,2) < 0 | ...
            obj_nextpos(:,2) > image_y);
        obj_outofbox = obj_active(ind_obj_outofbox);
        for ii = 1:length(obj_outofbox)
            oo = obj_outofbox(ii);
            time_bomb([time_bomb(:).id] == oo).timeleft = 0;
        end
        
    end
    
    % Step 9: Update the timer that is set for each object and delete those
    % objects of which timer values are expired
    for ii = find([time_bomb(:).starttime] < tt)
        time_bomb(ii).timeleft = time_bomb(ii).timeleft - 1;
    end
    if sum([time_bomb(:).timeleft] <= 0) ~= 0
        time_bomb([time_bomb(:).timeleft] <= 0) = [];
    end
    
    % Step 10: Print user messages
    if mod(tt,100) == 0
        fprintf('Step 2: Assigning Objects (%d/%d) Done\n',tt,size(xy_blob,1)) ;
    end   
end
end