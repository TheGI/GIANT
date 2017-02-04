function [state_log] = CalculateState(xy_obj,ind_obj,coeff_hysteresis)

state_log = [];
for ii = 1:size(xy_obj,1)
    temp = [];
    state_previous = 0;
    for jj = 1:ind_obj(ii)
        if jj == 1
            if xy_obj(ii,jj,1) < 150
                temp(1,end+1) = 1;
                temp(2,end) = xy_obj(ii,jj,3);
            else
                temp(1,end+1) = 2;
                temp(2,end) = xy_obj(ii,jj,3);
            end
        else
            if temp(1,end) == 1
                if xy_obj(ii,jj,1) < 150 + coeff_hysteresis
                    temp(1,end+1) = 1;
                    temp(2,end) = xy_obj(ii,jj,3);
                else
                    temp(1,end+1) = 2;
                    temp(2,end) = xy_obj(ii,jj,3);
                end
            end
            if temp(1,end) == 2
                if xy_obj(ii,jj,1) < 150 - coeff_hysteresis
                    temp(1,end+1) = 1;
                    temp(2,end) = xy_obj(ii,jj,3);
                else
                    temp(1,end+1) = 2;
                    temp(2,end) = xy_obj(ii,jj,3);
                end
            end
        end
    end
    % left to right is 1
    % right to left is 2
    for jj = 1:size(temp,2)
        if temp(1,jj) ~= state_previous
            if state_previous ~= 0
                state_log(1,end+1) = ii;
                if state_previous == 1 && temp(1,jj) == 2
                    state_log(3,end) = 1;
                    state_log(2,end) = temp(2,jj);
                end
                if state_previous == 2 && temp(1,jj) == 1
                    state_log(3,end) = 2;
                    state_log(2,end) = temp(2,jj);
                end
            end
            state_previous = temp(1,jj);
        end
    end
    if mod(ii,100) == 0
        fprintf('Step 4: Finding State Changes (%d/%d) Done\n',ii,size(xy_obj,1));
    end
end

[~, ind_state] = sort(state_log(2,:));
state_log = state_log(:,ind_state);

end