testRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(testRoot,'site','docs'));
R=Lab6_Passage_Speed((0:250:2000)',1000,4);
assert(abs(R.mean_rpm-60)<1e-10);
assert(max(abs(R.interval_rpm-60))<1e-10);
assert(~any(R.review));
R2=Lab6_Passage_Speed((1:250:2001)',1000,4);
assert(abs(R2.mean_rpm-R.mean_rpm)<1e-10);
R3=Lab6_Passage_Speed([0 250 500 1000 1250]',1000,4);
assert(any(R3.review));
assert(R3.interval_rpm(3)==30); % missed crossing remains visible
failed=false; try, Lab6_Passage_Speed([0 1 1],1000,4); catch, failed=true; end
assert(failed);
failed=false; try, Lab6_Passage_Speed([0 NaN 2],1000,4); catch, failed=true; end
assert(failed);
failed=false; try, Lab6_Passage_Speed([0 1 2],0,4); catch, failed=true; end
assert(failed);
disp('Lab 6 passage-speed regression checks passed.');
% Molecular model: independent statistical check against its exact expectation.
R=Lab6_Molecular_MC(150000,300,360,300,1,402);
assert(abs(R.deltaP_over_p-R.analytic_deltaP_over_p)<6*R.standard_error);
Z=Lab6_Molecular_MC(150000,300,300,300,1,403);
assert(abs(Z.deltaP_over_p)<6*Z.standard_error);
S=Lab6_Molecular_MC(2000,300,360,300,0,404);
assert(S.deltaP_over_p==0 && S.analytic_deltaP_over_p==0);
C=Lab6_Molecular_MC(150000,300,300,360,1,405);
assert(C.deltaP_over_p<0);
assert(abs(C.deltaP_over_p-C.analytic_deltaP_over_p)<6*C.standard_error);
assert(abs(R.hotPressure_over_p-(1+sqrt(360/300))/2)<0.02);
disp('Lab 6 molecular Monte Carlo checks passed.');
% Time alignment and weighted speed: two known passage sequences.
tmp=tempname;mkdir(tmp);cleanup=onCleanup(@() rmdir(tmp,'s'));
writetable(table((100:250:2100)','VariableNames',{'frame'}),fullfile(tmp,'a.csv'));
writetable(table((100:500:4100)','VariableNames',{'frame'}),fullfile(tmp,'b.csv'));
L=table(["A";"B"],["a.csv";"b.csv"],[1000;1000],[4;4],[100;50],[.2;.3],...
 [100;100],[0;0],[4;4],["cool";"cool"],...
 'VariableNames',{'run_id','passage_csv','capture_fps','passages_per_revolution','lux','distance_m','lamp_on_frame','window_start_s','window_end_s','initial_state'});
[S,C]=Lab6_Compare_Runs(L,tmp);
assert(abs(S.mean_rpm(1)-60)<1e-10 && abs(S.mean_rpm(2)-30)<1e-10);
assert(abs(C{1}.physical_interval_time_s(1)-.125)<1e-10);
assert(S.covered_start_s(1)==0 && S.covered_end_s(1)==2);
disp('Lab 6 matched-window comparison checks passed.');

% Segmented acquisition: different actual frame rates and origins, no cross-clip intervals.
writetable(table([50;200;450;700],'VariableNames',{'frame'}),fullfile(tmp,'start_on.csv'));
writetable(table([0;250;500],'VariableNames',{'frame'}),fullfile(tmp,'late_on.csv'));
writetable(table([300;1300;2300],'VariableNames',{'frame'}),fullfile(tmp,'start_off.csv'));
writetable(table([100;500],'VariableNames',{'frame'}),fullfile(tmp,'too_few.csv'));
L=table(["A";"A";"A";"A";"B";"B"],...
    ["on_start";"on_late";"off_start";"off_late";"on_start";"off_late"],...
    ["start_on.csv";"late_on.csv";"start_off.csv";"";"too_few.csv";""],...
    ["recorded";"recorded";"recorded";"stationary";"recorded";"not_run"],...
    [1000;500;1000;NaN;1000;NaN],[4;4;4;NaN;4;NaN],...
    [100;100;100;100;50;NaN],[.2;.2;.2;.2;.3;NaN],...
    [100;NaN;300;NaN;0;NaN],[NaN;64;NaN;62;NaN;NaN],...
    'VariableNames',{'run_id','clip_phase','passage_csv','status','capture_fps',...
    'passages_per_revolution','lux','distance_m','switch_frame','delay_s'});
[S,I] = Lab6_Analyze_Clips(L,tmp);
assert(all(abs(S.mean_rpm(1:3)-[60;30;15])<1e-10));
assert(all(isnan(S.mean_rpm(4:6))));
assert(isequal(S.analysis_status(4:6),["stationary";"insufficient";"not_run"]));
assert(height(I)==6 && all(S.measured_intervals(1:3)==2));
assert(abs(S.covered_start_s(1)-.1)<1e-12 && S.covered_start_s(2)==64);
assert(S.covered_start_s(3)==0 && all(I.clock_reference(5:6)=="lamp_off"));
assert(all(I.interval_end_s-I.interval_start_s<=1.01));
failed = false;
try
    L.delay_s(2) = NaN;
    Lab6_Analyze_Clips(L,tmp);
catch
    failed = true;
end
assert(failed,'An unrecorded late delay must not default to 60 s.');
disp('Lab 6 separate-clip and stopped observations passed.');
