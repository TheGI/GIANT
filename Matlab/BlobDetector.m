function [xy_blob] = BlobDetector(PathName, fileList, ...
    coeff_bw, coeff_arealim, coeff_cluster, debug)

xy_blob = [];
if length(coeff_arealim) == 1
    coeff_arealim = [coeff_arealim Inf];
end

for i = 2:numel(fileList)
    im_cur = imread([PathName fileList(i).name]);
    im_prev = imread([PathName fileList(i-1).name]);
    if size(im_cur,3)==3
        im_grayCur = rgb2gray(im_cur);
    else
        im_grayCur = im_cur;
    end
    if size(im_prev,3)==3
        im_grayPrev = rgb2gray(im_prev);
    else
        im_grayPrev = im_prev;
    end
    im_gray = (im_grayCur - im_grayPrev);
    im_gray = im_gray * 3;
    im_gray = medfilt2(im_gray);
    
    im_bw = im2bw(im_gray,coeff_bw(i)/256);
    %     im_bw = imopen(im_bw, strel('disk', 2, 4));
    im_bw = imclose(im_bw, strel('disk', 10, 8));
    im_bw= imfill(im_bw,'holes');
    
    s=regionprops(im_bw,im_gray,'Centroid','Area');
    centroids = vertcat(s.Centroid);
    
    
    
    if numel(centroids)>0
        ind_centroids = centroids(:,1)~=1 & centroids(:,2)~=1 & ...
            centroids(:,1)~=size(im_gray,2) & ...
            centroids(:,2)~=size(im_gray,1) & ...
            vertcat(s.Area)>coeff_arealim(1) & ...
            vertcat(s.Area)<coeff_arealim(2); % remove regions on edge, too small, or too big
        centroids=centroids(ind_centroids,:);
        s=s(ind_centroids);
    end
    
    if debug
        subplot(1,2,1);
        imshow(im_cur);
        subplot(1,2,2);
        imshow(im_bw);
        if numel(centroids) ~= 0
            hold on;
            plot(centroids(:,1),centroids(:,2),'ro');
            hold off;
        end
        drawnow;
    end
    
    ind_blob_range = [];
    dim = size(centroids);
    if ~isempty(centroids)
        for j = 1:dim(1)
            idx = rangesearch(centroids,centroids(j,:),coeff_cluster);
            ind_blob_range(j,1:length(idx{1})) = sort(cell2mat(idx));
        end
        
        ind_blob_range = unique(ind_blob_range,'rows');
        assignment = ones(1,length(unique(ind_blob_range)))*Inf;
        
        for j = 1:size(ind_blob_range,1)
            finddup_flag = 0;
            for k = 1:size(assignment,1)
                if sum(intersect(ind_blob_range(j,:),assignment(k,:)))
                    finddup_flag = 1;
                    temp = union(ind_blob_range(j,:),assignment(k,:));
                    temp = temp(temp ~= 0);
                    assignment(k,1:length(temp)) = temp;
                end
            end
            if ~finddup_flag
                assignment(end+1,1:size(ind_blob_range(j,:),2)) = ind_blob_range(j,:);
            end
        end
        assignment(1,:) = [];
        
        for j = 1:size(assignment,1)
            ind_assignment = find(assignment(j,:) ~= Inf & assignment(j,:) ~= 0);
            if ~isempty(ind_assignment)
                xy_blob(i,j,:) = [mean(centroids(assignment(j,ind_assignment),1)),...
                    mean(centroids(assignment(j,ind_assignment),2))];
            end
        end
    end
    
    if mod(i,100) == 0
        fprintf('Step 1: Detecting Objects (%d/%d) Done\n',i,numel(fileList)) ;
    end
end
end