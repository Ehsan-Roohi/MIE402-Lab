% MATLAB R2024b: known synthetic signals, importer edge cases and complete UI path.
repo=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(repo,'site','docs'));
set(0,'DefaultFigureVisible','off'); rng(402);
out=fullfile(tempdir,'lab5_check'); if ~exist(out,'dir'), mkdir(out); end
P=struct('m',.65,'kFixed',10,'kDrive',12,'c',.32,'Y',.012);
wn=sqrt(22/.65); a=P.c/(2*P.m); wd=sqrt(wn^2-a^2); t=(0:.04:35)';
for amplitude=[.01 .025 .04]
    x=.2+amplitude*exp(-a*t).*sin(wd*t+.2)+1e-5*randn(size(t));
    R=Lab5_Analyze_Record(t,x,P,'impulse');
    assert(abs(R.fd_fit_Hz-wd/(2*pi))<.005); assert(abs(R.c_est_Ns_m-P.c)<.015);
end
for f=[.25 .45 .65 1.1 1.4 1.7]
    w=2*pi*f; H=P.kDrive/complex(22-P.m*w^2,P.c*w);
    x=.17+.0001*t+abs(H)*P.Y*cos(w*t-.7)+1e-5*randn(size(t));
    R=Lab5_Analyze_Record(t,x,P,'harmonic',f);
    assert(abs(R.gain-abs(H))<.002); assert(R.rmse_m<2e-5);
    assert(abs(R.X_theory_m-P.Y*abs(H))<1e-12);
    assert(abs(R.phase_lag_theory_rad+angle(H))<1e-12);
    expected=R.offset_m+P.Y*abs(H)*cos(w*t-.7);
    assert(max(abs(R.theory-expected))<1e-5);
end
% A fit to observations must not force agreement with analytical amplitude.
f=wn/(2*pi); w=2*pi*f; H=P.kDrive/complex(22-P.m*w^2,P.c*w);
R=Lab5_Analyze_Record(t,.17+.8*P.Y*abs(H)*cos(w*t+.4),P,'harmonic',f);
assert(abs(R.amplitude_error_percent+20)<1e-8);
assert(abs(R.phase_lag_theory_rad-pi/2)<1e-10);
assert(abs(R.X_theory_m-R.X_m)>0.1*R.X_theory_m);
% Metadata lines, units, index column, numeric text, millimeters in XLSX.
raw=cell(numel(t)+4,3); raw(1,:)={'Vernier export','',''};
raw(3,:)={'Index','Time','Position'};raw(4,:)={'','s','m'};
x=.17+.02*cos(2*pi*.65*t); raw(5:end,1)=num2cell((1:numel(t))');
raw(5:end,2)=cellstr(compose('%.15g',t));raw(5:end,3)=cellstr(compose('%.15g',x));
csv=fullfile(out,'test.csv'); writecell(raw,csv);
[tt,xx]=Lab5_Read_Vernier(csv); assert(max(abs(tt-t))<1e-8); assert(max(abs(xx-x))<1e-8);
xlsx=fullfile(out,'test.xlsx');writecell(raw,xlsx,'Sheet','Cart');
[tt,xx]=Lab5_Read_Vernier(xlsx,[2 3],'Cart');assert(max(abs(xx-x))<1e-8);
% An ambiguous second run must request column selection, not silently pick one.
amb=[raw raw]; writecell(amb,fullfile(out,'amb.csv'));
failed=false;try,Lab5_Read_Vernier(fullfile(out,'amb.csv'));catch e,failed=strcmp(e.identifier,'Lab5:Columns');end;assert(failed);
% Time reset: reject instead of sorting separate runs into one.
failed=false;try,Lab5_Analyze_Record([t;t], [x;x],P,'harmonic',.65);catch,failed=true;end;assert(failed);
% Complete student launcher: a sweep with distinct input travel at each speed.
% Select high frequency first and verify frequency/ratio pairs after sorting.
lowData = raw;
lowData(5:end,3) = num2cell(.19 + .012*cos(2*pi*.40*t + .3));
writecell(lowData,fullfile(out,'test_low.csv'));
mock=fullfile(out,'mock');if ~exist(mock,'dir'),mkdir(mock);end
fid=fopen(fullfile(mock,'uigetfile.m'),'w');
fprintf(fid,'function [f,p]=uigetfile(varargin)\nglobal L5_NAMES L5_FOLDER; f=L5_NAMES; p=L5_FOLDER;\nend\n');
fclose(fid);
fid=fopen(fullfile(mock,'input.m'),'w');fprintf(fid,'function x=input(varargin)\nglobal L5_INPUT L5_I;if L5_I<=8, assert(isempty(findall(0,''Type'',''figure'')),''Unexpected preliminary figure'');end;x=L5_INPUT{L5_I};L5_I=L5_I+1;\nend\n');fclose(fid);
global L5_NAMES L5_FOLDER L5_INPUT L5_I;
L5_NAMES={'test.csv','test_low.csv'}; L5_FOLDER=out;
L5_INPUT={2,P.m,10,12,P.c,[],[0 35],1,39,.024,[],[0 35],1,24,.010}; L5_I=1;
addpath(mock,'-begin');rehash;R=Run_Lab5_Forced_Response;
resultsDir=fullfile(out,'Lab5_Results');
assert(exist(fullfile(resultsDir,'Lab5_Harmonic_Summary.csv'),'file')==2);
assert(exist(fullfile(resultsDir,'Lab5_Frequency_Response.png'),'file')==2);
assert(exist(fullfile(resultsDir,'Lab5_X_over_Y_vs_Drive_Frequency_Hz.png'),'file')==2);
assert(numel(findall(0,'Type','figure'))==4); % two run figures, report plot, Bode plot
S=readtable(fullfile(resultsDir,'Lab5_Harmonic_Summary.csv'));
expected=[.40, .012/.005; .65, .020/.012];
assert(max(abs(sortrows([S.drive_Hz,S.gain])-expected),[],'all')<1e-6);
assert(ismember('X_theory_peak_m',S.Properties.VariableNames));
assert(exist(fullfile(resultsDir,'test_comparison.txt'),'file')==2);
F=readtable(fullfile(resultsDir,'test_fit.csv'));
assert(ismember('theory_m',F.Properties.VariableNames));

reportFig=findall(0,'Type','figure','Name','Report: X/Y vs drive frequency');
assert(isscalar(reportFig));
reportAxes=findobj(reportFig,'Type','axes');
assert(isscalar(reportAxes) && strcmp(reportAxes.XScale,'linear') && strcmp(reportAxes.YScale,'linear'));
assert(contains(reportAxes.XLabel.String,'Hz') && contains(erase(reportAxes.YLabel.String,' '),'X/Y'));
points=findobj(reportAxes,'Type','line','LineStyle','none');
assert(isscalar(points) && ~strcmp(points.Marker,'none'));
assert(max(abs(sortrows([points.XData(:),points.YData(:)])-expected),[],'all')<1e-6);
curve=findobj(reportAxes,'Type','line','-not','LineStyle','none');
assert(isscalar(curve) && numel(curve.XData)>2);
freq=curve.XData(:);
assert(all(isfinite(freq)) && all(diff(freq)>0) && freq(1)<=min(expected(:,1)) && freq(end)>=max(expected(:,1)));
omega=2*pi*freq;
theory=P.kDrive./hypot(P.kFixed+P.kDrive-P.m*omega.^2,P.c*omega);
assert(max(abs(curve.YData(:)-theory))<1e-10);
bodeAxes=findall(0,'Type','axes','XScale','log');
assert(isscalar(bodeAxes));
bodePoints=findobj(bodeAxes,'Type','line','LineStyle','none');
assert(isscalar(bodePoints));
expectedBode=[2*pi*expected(:,1),20*log10(expected(:,2))];
assert(max(abs(sortrows([bodePoints.XData(:),bodePoints.YData(:)])-expectedBode),[],'all')<1e-6);
close all;L5_NAMES='test.csv';L5_INPUT={1,P.m,10,12,[],[0 35],1};L5_I=1;
% Overwrite input CSV with a transient and retest the other launcher branch.
x=.2+.04*exp(-a*t).*sin(wd*t);raw(5:end,3)=num2cell(x);writecell(raw,csv);
R=Run_Lab5_Forced_Response;assert(abs(R{1}.c_est_Ns_m-P.c)<.005);
assert(exist(fullfile(out,'Lab5_Results','Lab5_Impulse_Summary.csv'),'file')==2);
rmpath(mock);close all;
fprintf('LAB 5 PASSED: CSV/XLSX, 3 decay amplitudes, 6 harmonic frequencies, both complete launcher paths. Synthetic data only.\n');
