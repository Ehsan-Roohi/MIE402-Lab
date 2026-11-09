function [summary,records] = Lab6_Compare_Runs(logTable,baseFolder)
% Compare verified passage tables using the same requested physical window.
required={'run_id','passage_csv','capture_fps','passages_per_revolution',...
 'lux','distance_m','lamp_on_frame','window_start_s','window_end_s','initial_state'};
assert(all(ismember(required,logTable.Properties.VariableNames)),'Use Lab6_Comparison_Log.csv headers.');
n=height(logTable);assert(n>=1,'The run log is empty.');records=cell(n,1);
values=nan(n,8);
for i=1:n
 f=char(string(logTable.passage_csv(i)));assert(~isempty(f),'Enter passage_csv for every row.');
 if ~isfile(f),f=fullfile(baseFolder,f);end
 a=readtable(f,'VariableNamingRule','preserve');
 assert(ismember('frame',a.Properties.VariableNames),'Each passage CSV needs a frame column.');
 frames=a.frame;fps=logTable.capture_fps(i);p=logTable.passages_per_revolution(i);
 on=logTable.lamp_on_frame(i);t0=logTable.window_start_s(i);t1=logTable.window_end_s(i);
 validateattributes([fps,p],{'numeric'},{'positive','finite'});
 validateattributes([on,t0,t1],{'numeric'},{'finite','nonnegative'});
 assert(t1>t0,'window_end_s must exceed window_start_s.');
 t=(frames-on)/fps;frames=frames(t>=t0 & t<=t1);
 R=Lab6_Passage_Speed(frames,fps,p);
 physical=(R.frame-on)/fps;
 midpoint=(physical(1:end-1)+physical(2:end))/2;dt=diff(physical);
 early=midpoint<(t0+t1)/2;late=~early;
 if any(early),e=60*sum(early)/(p*sum(dt(early)));else,e=NaN;end
 if any(late),l=60*sum(late)/(p*sum(dt(late)));else,l=NaN;end
 change=100*(l-e)/e;
 values(i,:)=[R.mean_rpm,e,l,change,physical(1),physical(end),numel(frames)-1,sum(R.review)];
 R.physical_interval_time_s=midpoint;R.run_id=string(logTable.run_id(i));records{i}=R;
end
summary=[logTable array2table(values,'VariableNames',{'mean_rpm','early_rpm','late_rpm','early_to_late_percent',...
 'covered_start_s','covered_end_s','verified_intervals','intervals_to_review'})];
% Means cover first-to-last retained crossing, not unobserved window edges.
end
