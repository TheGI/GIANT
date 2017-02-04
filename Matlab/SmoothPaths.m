function [xy_obj, ind_obj] = SmoothPaths(xy_obj, ind_obj, coeff_smooth)

if nargin < 3
    coeff_smooth = 5;
end

for ii = 1:size(xy_obj,1)
    xy_obj(ii,1:ind_obj(ii),1) = smooth(xy_obj(ii,1:ind_obj(ii),1),coeff_smooth);
    xy_obj(ii,1:ind_obj(ii),2) = smooth(xy_obj(ii,1:ind_obj(ii),2),coeff_smooth);
    
    if (ind_obj(ii) > 1)
        t = xy_obj(ii,1:ind_obj(ii),3);
        tt = xy_obj(ii,1,3):xy_obj(ii,ind_obj(ii),3);
        x = [];
        y = [];
        for jj = 1:length(tt)
            ind = find(t == tt(jj));
            if ind
                x(jj) = xy_obj(ii,ind,1);
                y(jj) = xy_obj(ii,ind,2);
            else
                x(jj) = 0;
                y(jj) = 0;
            end
        end
        ind_nonzero = find(x ~= 0);
        if ~isempty(ind_nonzero)
            x = interp1(tt(ind_nonzero),x(ind_nonzero), tt);
            y = interp1(tt(ind_nonzero),y(ind_nonzero), tt);
            
            xy_obj(ii,1:length(tt),1) = x;
            xy_obj(ii,1:length(tt),2) = y;
            xy_obj(ii,1:length(tt),3) = tt;
            ind_obj(ii) = length(tt);
        end
    end
    if mod(ii,100) == 0
        fprintf('Step 3: Smoothing Paths (%d/%d) Done\n',ii,size(xy_obj,1));
    end
end

end