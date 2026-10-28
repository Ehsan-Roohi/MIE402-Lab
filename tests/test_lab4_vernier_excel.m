% MATLAB-only integration tests with synthetic workbook; not student data.
repoRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot,'site','docs'));set(0,'DefaultFigureVisible','off');
out=fullfile(tempdir,'lab4_excel_checks');if ~exist(out,'dir'),mkdir(out);end
file=fullfile(out,'synthetic_vernier.xlsx');
t=(0:0.04:10)';b=7.30;a=.11;y=1.96+.35*exp(-a*t).*cos(b*t+.6);
C=cell(numel(t)+4,5);C{1,1}='Vernier Graphical Analysis';
C{2,2}='Data Set 1: Time';C{2,4}='Data Set 1: Force';C{3,2}='ms';C{3,4}='mN';
for i=1:numel(t)
 C{i+4,2}=1000*t(i);C{i+4,4}=sprintf('%.9f',1000*y(i));
end
writecell({'Notes';'Select the spring data sheet'},file,'Sheet','Notes');
writecell(C,file,'Sheet','Spring A');
allSheets=Lab4_Vernier_Sheets(file);assert(numel(allSheets)>=2);assert(any(strcmp(allSheets,'Spring A')));
failed=false;try,Lab4_Read_Vernier_Force(file,'');catch,failed=true;end;assert(failed,'Ambiguous worksheets must not be selected silently.');
[A,names,sheet]=Lab4_Read_Vernier_Force(file,'Spring A');assert(strcmp(sheet,'Spring A'));
assert(~isempty(regexpi(names{2},'Time')));assert(~isempty(regexpi(names{4},'Force')));
assert(sum(isfinite(A(:,2)) & isfinite(A(:,4)))==numel(t));
c=struct('mode','file','file',file,'sheet','Spring A','label','A','massValue',200,'massUnit','g', ...
 'timeColumn',2,'forceColumn',4,'timeScale',.001,'forceScale',.001,'startTime',400,'endTime',9600,'damped',true,'outputDir',out,'makePlots',true);
r=Lab4_Spring_Stiffness_Analysis(c);
assert(abs(r.B_rad_s-b)<.01);assert(abs(r.alpha_s_inv-a)<.01);assert(abs(r.k_N_m-10.66042)<.02);
assert(exist(fullfile(out,'A_Force_Fit.png'),'file')==2);
fprintf('MATLAB Excel test: B=%.6f alpha=%.6f k=%.6f R2=%.6f\n',r.B_rad_s,r.alpha_s_inv,r.k_N_m,r.R2);
% Exercise the actual no-argument student flow with mocked dialogs and input.
mock=fullfile(out,'ui_mock');if ~exist(mock,'dir'),mkdir(mock);end
fid=fopen(fullfile(mock,'uigetdir.m'),'w');fprintf(fid,'function varargout=uigetdir(varargin)\nerror(''A folder-only picker must not open.'');\nend\n');fclose(fid);
fid=fopen(fullfile(mock,'uigetfile.m'),'w');fprintf(fid,'function [f,p]=uigetfile(varargin)\nglobal SPRING_TEST_FILE; [p,n,e]=fileparts(SPRING_TEST_FILE);f=[n e];p=[p filesep];\nend\n');fclose(fid);
fid=fopen(fullfile(mock,'listdlg.m'),'w');fprintf(fid,'function [i,ok]=listdlg(varargin)\nglobal SPRING_TEST_SHEET_INDEX;i=SPRING_TEST_SHEET_INDEX;ok=1;\nend\n');fclose(fid);
fid=fopen(fullfile(mock,'input.m'),'w');fprintf(fid,'function x=input(varargin)\nglobal SPRING_TEST_INPUTS SPRING_TEST_NEXT;x=SPRING_TEST_INPUTS{SPRING_TEST_NEXT};SPRING_TEST_NEXT=SPRING_TEST_NEXT+1;\nend\n');fclose(fid);
global SPRING_TEST_FILE SPRING_TEST_SHEET_INDEX SPRING_TEST_INPUTS SPRING_TEST_NEXT;
SPRING_TEST_FILE=file;SPRING_TEST_SHEET_INDEX=find(strcmp(allSheets,'Spring A'));
SPRING_TEST_INPUTS={1,'A',200,'g',2,2,4,2,2,400,9600,2,[]};SPRING_TEST_NEXT=1;
addpath(mock,'-begin');rehash;results=Run_Lab4_Spring_Stiffness();rmpath(mock);clear input uigetfile uigetdir listdlg;
assert(numel(results)==1);assert(abs(results.B_rad_s-b)<.01);assert(abs(results.k_N_m-10.66042)<.02);
assert(exist(file,'file')==2);
fprintf('MATLAB student entry: Excel file chooser, worksheet, columns and fit passed.\n');
