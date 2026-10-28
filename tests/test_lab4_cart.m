% Synthetic cart data: verify the full student script and output files in MATLAB.
repo=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(repo,'site','docs'));
set(0,'DefaultFigureVisible','off');out=fullfile(tempdir,'cart_response_check');if ~exist(out,'dir'),mkdir(out);end
f=fullfile(out,'cart_test.csv');t=(0:.04:15)';x=.04*exp(-.15*t).*cos(2*pi*1.2*t);writetable(table(t,x,'VariableNames',{'Time','Position'}),f);
mock=fullfile(out,'mock');if ~exist(mock,'dir'),mkdir(mock);end
fid=fopen(fullfile(mock,'uigetfile.m'),'w');fprintf(fid,'function [f,p]=uigetfile(varargin)\nglobal CART_TEST_FILE;[p,n,e]=fileparts(CART_TEST_FILE);f=[n e];p=[p filesep];\nend\n');fclose(fid);
fid=fopen(fullfile(mock,'input.m'),'w');fprintf(fid,'function x=input(varargin)\nglobal CART_TEST_INPUTS CART_TEST_NEXT;x=CART_TEST_INPUTS{CART_TEST_NEXT};CART_TEST_NEXT=CART_TEST_NEXT+1;\nend\n');fclose(fid);
global CART_TEST_FILE CART_TEST_INPUTS CART_TEST_NEXT;CART_TEST_FILE=f;CART_TEST_INPUTS={.5,14,14,0,0,15,1};CART_TEST_NEXT=1;
addpath(mock,'-begin');rehash;run(fullfile(repo,'site','docs','MIE402_Lab4_Analyze_Free_Response.m'));
assert(numel(findall(0,'Type','figure'))==2,'Expected two figure windows, with three subplots in the first.');
assert(exist(fullfile(out,'Lab4_results','cart_test_time_and_decay.png'),'file')==2);
assert(exist(fullfile(out,'Lab4_results','cart_test_FFT.png'),'file')==2);
assert(exist(fullfile(out,'Lab4_results','cart_test_summary.csv'),'file')==2);
q=readtable(fullfile(out,'Lab4_results','cart_test_summary.csv'));assert(abs(q.fd_Time_Hz-1.2)<.03);
fprintf('CART SCRIPT PASSED: MATLAB, meters, both output figures and summary saved.\n');
