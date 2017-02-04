function [coeff_bw, coeff_speed,...
    coeff_dist, coeff_cluster, coeff_arealim,...
    coeff_hysteresis,coeff_smooth,coeff_antsize] = CalculateCoefficients(...
    im_mean,im_std,max_speed,min_speed, max_bw, min_bw, max_dist,...
    min_dist, max_cluster, max_area, min_area, ...
    max_histeresis,max_smooth,max_antsize)

im_coeff = im_mean .* im_std;

c_speed1 = (max_speed-min_speed)/(min(im_coeff)-max(im_coeff));
c_speed2 = max_speed-min(im_coeff)*c_speed1;
c_bw1 = (max_bw-min_bw)/(max(im_coeff)-min(im_coeff));
c_bw2 = min_bw-min(im_coeff)*c_bw1;
c_dist1 = (max_dist-min_dist)/(max(im_coeff)-min(im_coeff));
c_dist2 = min_dist-min(im_coeff)*c_dist1;

for i = 1:length(im_coeff)
    coeff_speed(i) = c_speed1*im_coeff(i)+c_speed2;
    coeff_bw(i) = c_bw1*im_coeff(i)+c_bw2;
    coeff_dist(i) = c_dist1*im_coeff(i)+c_dist2;
end
coeff_cluster = max_cluster;
coeff_arealim = [min_area max_area];
coeff_hysteresis = max_histeresis;
coeff_smooth = max_smooth;
coeff_antsize = max_antsize;
end
