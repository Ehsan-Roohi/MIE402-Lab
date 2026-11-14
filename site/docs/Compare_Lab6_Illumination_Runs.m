% LAB 6: compare separate clips from your illumination runs.
% Mark each clip separately, then complete Lab6_Comparison_Log.csv.
clear; clc;
[fn,folder] = uigetfile('*.csv','Select your completed Lab 6 comparison log');
if isequal(fn,0), return; end
logTable = readtable(fullfile(folder,fn),'VariableNamingRule','preserve','TextType','string');
out = fullfile(folder,'Lab6_Comparison_Results');
if ~ismember('clip_phase',logTable.Properties.VariableNames)
    run(fullfile(fileparts(mfilename('fullpath')),'Lab6_Legacy_Comparison.m'));
    return;
end
[summary,intervals] = Lab6_Analyze_Clips(logTable,folder);
if ~isfolder(out), mkdir(out); end
writetable(summary,fullfile(out,'Lab6_Clip_Summary.csv'));
writetable(intervals,fullfile(out,'Lab6_Clip_Intervals.csv'));

runIDs = unique(string(summary.run_id),'stable');
colors = lines(numel(runIDs));
fig = figure('Color','w','Position',[100 100 1000 900]);
tiledlayout(3,1);
phases = ["on_start","on_late";"off_start","off_late"];
labels = ["Time since lamp ON (s)","Time since lamp OFF (s)"];
markers = {'o','s'};
for j = 1:2
    nexttile; hold on; grid on;
    for k = 1:numel(runIDs)
        for m = 1:2
            t = intervals(intervals.run_id==runIDs(k) & intervals.clip_phase==phases(j,m),:);
            if isempty(t), continue; end
            plot(t.interval_midpoint_s,t.interval_rpm,markers{m},'LineStyle','none',...
                'Color',colors(k,:),'DisplayName',char(runIDs(k)+" "+phases(j,m)));
            flagged = t.review;
            if any(flagged)
                plot(t.interval_midpoint_s(flagged),t.interval_rpm(flagged),'rx','HandleVisibility','off');
            end
        end
    end
    xlabel(labels(j)); ylabel('Measured interval speed (rpm)');
    if any(ismember(intervals.clip_phase,phases(j,:))), legend('Location','best','Interpreter','none'); end
end
nexttile; hold on; grid on;
late = summary(lower(strtrim(string(summary.clip_phase)))=="on_late" & isfinite(summary.mean_rpm),:);
for i = 1:height(late)
    color = colors(runIDs==string(late.run_id(i)),:);
    lux = str2double(string(late.lux(i)));
    plot(lux,late.mean_rpm(i),'o','Color',color,'MarkerFaceColor',color);
    text(lux,late.mean_rpm(i),sprintf('  %s, %g s',char(string(late.run_id(i))),...
        str2double(string(late.delay_s(i)))),'Interpreter','none');
end
xlabel('Measured illuminance (lux)');
ylabel('Late-on clip mean (rpm)');
exportgraphics(fig,fullfile(out,'Lab6_Illumination_Comparison.png'),'Resolution',300);
exportgraphics(fig,fullfile(out,'Lab6_Illumination_Comparison.pdf'),'ContentType','vector');
disp(summary(:,{'run_id','clip_phase','analysis_status','mean_rpm','covered_start_s','covered_end_s','intervals_to_review'}));
fprintf('Ranges and means use measured crossings within each clip. Check red marks in the video.\n');
fprintf('Compare late-on speeds at similar elapsed delays and thermal conditions.\n');
fprintf('Saved to %s\n',out);
