% LAB 6: ROTATION SPEED FROM VERIFIED VIDEO PASSAGES
% Unzip the complete bundle. Click Run on THIS script.
% CSV needs one column named frame, containing consecutive passage frames.
clear; clc;
[fn,folder]=uigetfile({'*.csv;*.xlsx;*.xls','Passage table (*.csv, *.xlsx, *.xls)';'*.*','All files'},'Select passage frames');
if isequal(fn,0), return; end
T=readtable(fullfile(folder,fn),'VariableNamingRule','preserve');
names=string(T.Properties.VariableNames);
col=find(strcmpi(strtrim(names),'frame'),1);
assert(~isempty(col),'The table needs a column named frame. Use the supplied template.');
frames=T{:,col};
if ~isnumeric(frames), frames=str2double(string(frames)); end
assert(all(isfinite(frames)),'The frame column contains missing or nonnumeric entries. Review the table.');
answ=inputdlg({'ACTUAL capture frame rate (fps):','Verified passages per FULL revolution (1 for a unique vane):'},'Lab 6 timing',[1 65],{'',''});
if isempty(answ), return; end
fps=str2double(answ{1}); p=str2double(answ{2});
R=Lab6_Passage_Speed(frames,fps,p);
out=fullfile(folder,[erase(fn,{'.csv','.xlsx','.xls'}) '_Results']);
if ~exist(out,'dir'), mkdir(out); end
S=table(R.interval_time_s,R.interval_rpm,R.omega_rad_s,R.review,...
 'VariableNames',{'time_since_first_passage_s','rpm','omega_rad_s','review_video'});
writetable(S,fullfile(out,'interval_speed.csv'));
save(fullfile(out,'Lab6_Result.mat'),'R');
fig=figure('Color','w','Name','Lab 6 rotation speed');
tiledlayout(2,1);
nexttile; plot(R.time_s,(0:numel(frames)-1)/p,'ko','MarkerSize',5);
xlabel('Time since first marked passage (s)'); ylabel('Cumulative revolutions'); grid on;
nexttile; plot(R.interval_time_s,R.interval_rpm,'k.-','LineWidth',1); hold on;
plot(R.interval_time_s(R.review),R.interval_rpm(R.review),'ro','MarkerSize',9);
xlabel('Time since first marked passage (s)'); ylabel('Interval rotation speed (rpm)'); grid on;
if any(R.review)
 legend('All measured intervals','Review these intervals in the video','Location','best');
 warning('Lab6:Review','Large interval changes found. Review the video; these are not automatically removed or interpolated.');
end
exportgraphics(fig,fullfile(out,'Lab6_Rotation_Speed.png'),'Resolution',300);
exportgraphics(fig,fullfile(out,'Lab6_Rotation_Speed.pdf'),'ContentType','vector');
fid=fopen(fullfile(out,'measurement_summary.txt'),'w');
assert(fid>=0,'Could not write summary. Choose a writable data folder.');
fprintf(fid,'Actual capture fps: %.12g\nPassages per revolution: %d\n',fps,p);
fprintf(fid,'Marked passages: %d\nElapsed time: %.9g s\n',numel(frames),R.time_s(end));
fprintf(fid,'Interval-averaged rotation speed: %.9g rpm\n',R.mean_rpm);
fprintf(fid,'Intervals needing video review: %d\n',sum(R.review)); fclose(fid);
fprintf('Saved results to %s\nMean speed over the selected interval: %.4g rpm\n',out,R.mean_rpm);
% Mean speed describes only the selected interval. Select a settled interval
% separately if you want steady speed. This is speed magnitude, not direction.
