function PlotStates(state_log,binsize)
timespace = linspace(state_log(2,1),state_log(2,end)+1,binsize);
left2right = [];
right2left = [];
for i = 1:length(timespace)-1
left2right(i) = sum(state_log(3,:) == 1 & ...
state_log(2,:) >= timespace(i) & state_log(2,:) < timespace(i+1));
right2left(i) = sum(state_log(3,:) == 2 & ...
state_log(2,:) >= timespace(i) & state_log(2,:) < timespace(i+1));
end
hold on;
plot(left2right,'r-');
plot(right2left,'b-');
legend('Left to Right','Right to Left');
hold off;
end