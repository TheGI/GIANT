function [xy_obj_out, ind_obj_out, state_log_out] = CleanUpObjects(xy_obj,ind_obj,state_log,coeff_hysteresis)
xy_obj_out = xy_obj;
ind_obj_out = ind_obj;
state_log_out = state_log;
state_obj = unique(state_log(1,:));
ind_obj_erase = 1:size(xy_obj,1);
ind_obj_erase(state_obj) = [];
xy_obj_out(ind_obj_erase,:,:) = [];
ind_obj_out(ind_obj_erase) = [];
state_log_out = CalculateState(xy_obj_out,ind_obj_out,coeff_hysteresis);
end