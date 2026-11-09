% LAB 6: COMPARE YOUR ILLUMINATION RUNS. Base MATLAB, no automatic tracking.
% First mark consecutive crossings using Mark_Lab6_Passage_Frames.m.
% Fill Lab6_Comparison_Log.csv; use a common window for matched comparisons.
clear;clc;
[fn,folder]=uigetfile('*.csv','Select your completed Lab6 comparison log');
if isequal(fn,0),return;end
logTable=readtable(fullfile(folder,fn),'VariableNamingRule','preserve','TextType','string');
[summary,records]=Lab6_Compare_Runs(logTable,folder);
out=fullfile(folder,'Lab6_Comparison_Results');if ~exist(out,'dir'),mkdir(out);end
writetable(summary,fullfile(out,'Lab6_Run_Comparison.csv'));
fig=figure('Color','w','Position',[100 100 1000 720]);tiledlayout(2,1);
nexttile;hold on;
for i=1:height(summary)
 R=records{i};plot(R.physical_interval_time_s,R.interval_rpm,'.-','DisplayName',char(R.run_id));
end
xlabel('Time since illumination on (s)');ylabel('Interval speed (rpm)');grid on;legend('Location','best');
nexttile;hold on;
for i=1:height(summary)
 plot(summary.lux(i),summary.mean_rpm(i),'o','MarkerSize',7);
 text(summary.lux(i),summary.mean_rpm(i),'  '+string(summary.run_id(i)),'Interpreter','none');
end
xlabel('Measured illuminance (lux), same lamp');ylabel('Selected-window mean speed (rpm)');grid on;
exportgraphics(fig,fullfile(out,'Lab6_Illumination_Comparison.png'),'Resolution',300);
exportgraphics(fig,fullfile(out,'Lab6_Illumination_Comparison.pdf'),'ContentType','vector');
disp(summary(:,{'run_id','mean_rpm','early_rpm','late_rpm','covered_start_s','covered_end_s','intervals_to_review'}));
fprintf('Means use the covered crossing interval. Inspect early/late differences before calling a run steady.\n');
fprintf('Keep warm-return runs separate from repeats begun after cooling. Saved to %s\n',out);
