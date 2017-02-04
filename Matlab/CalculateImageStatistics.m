function [im_mean, im_std] = CalculateImageStatistics(PathName, FileList)
im_mean = [];
im_std = [];
for i = [1:10:numel(FileList) numel(FileList)]
    im_cur = imread([PathName FileList(i).name]);
    im_mean(i) = mean2(im_cur)/255;
    im_std(i) = std2(im_cur)/255;
    if mod(i,100) == 1
        fprintf('Step 0: Calculating Brightness & Contrast (%d/%d) Done\n',i,numel(FileList));
    end
end
x = 1:length(im_std);
ind=find(im_std ~= 0);
im_std=interp1(x(ind),im_std(ind),x);
im_mean = interp1(x(ind),im_mean(ind),x);
im_std = smooth(im_std,10001);
im_mean = smooth(im_mean,10001);
end