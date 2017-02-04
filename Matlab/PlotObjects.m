function PlotObjects(PathName,FileList, xy_obj, ind_obj, xy_blob, state_log, StartFrame, EndFrame, StartTime, debug)
if EndFrame > numel(FileList)
    EndFrame = numel(FileList);
end
if StartFrame < 1
    StartFrame = 1;
end
if StartFrame > EndFrame
    error('Start Time must be earlier than End Time');
end

if ~debug
    for jj = StartFrame:EndFrame
        d = imread([PathName FileList(jj).name]);
        imshow(d);
        [r c v] = find(xy_obj(:,:,3) == jj);
        hold on;
        for ii = 1:length(r)
            plot(xy_obj(r(ii),c(ii),1),xy_obj(r(ii),c(ii),2),'ro');
            plot(xy_obj(r(ii),1:ind_obj(r(ii)),1),xy_obj(r(ii),1:ind_obj(r(ii)),2),'b-');
            text(xy_obj(r(ii),c(ii),1)+5,xy_obj(r(ii),c(ii),2),...
                num2str(r(ii)),'Color','green');
        end
        text(0,740,['Time: ' num2str(floor((jj*3/29.97 + StartTime)/3600)) ' : ' ...
            num2str(mod(floor((jj*3/29.97 + StartTime)/60),60)) ' : ' ...
            num2str(mod(floor((jj*3/29.97 + StartTime)),60))]);
        text(120,740,['Count: ' num2str(numel(find(state_log(2,:) <= jj)))]);
        text(240,740,['Frame: ' num2str(jj)]);
        hold off;
        drawnow;
    end
else
    for jj = StartFrame:EndFrame
        d = imread([PathName FileList(jj).name]);
        imshow(d);
        [r c v] = find(xy_blob(jj,:,1) ~= 0);
        hold on;
        for ii = 1:length(c)
            plot(xy_blob(jj,c(ii),1),xy_blob(jj,c(ii),2),'ro');
            text(xy_blob(jj,c(ii),1)+5,xy_blob(jj,c(ii),2),...
                '*','Color','green');
        end
        text(0,740,['Time: ' num2str(floor((jj*3/29.97 + StartTime)/3600)) ' : ' ...
            num2str(mod(floor((jj*3/29.97 + StartTime)/60),60)) ' : ' ...
            num2str(mod(floor((jj*3/29.97 + StartTime)),60))]);
        text(120,740,['Count: ' num2str(numel(find(state_log(2,:) <= jj)))]);
        text(240,740,['Frame: ' num2str(jj)]);
        hold off;
        drawnow;
    end
end
end