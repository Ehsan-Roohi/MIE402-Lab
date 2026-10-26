function results = Run_Lab4_Spring_Stiffness()
% Lab 4 - Spring stiffness analysis (vertical hanging-spring test)
% Open THIS file and click Run. No input arguments are required.
% Keep Lab4_Spring_Stiffness_Analysis.m in the same folder.
% This is separate from MIE402_Lab4_Analyze_Free_Response.m (the cart).
% B in F=A*sin(B*t+phase)+offset is rad/s. Include hanger in hanging mass.
fprintf('\nLAB 4 - SPRING STIFFNESS (vertical test, one spring at a time)\n');
fprintf('Use total HANGING mass, including hanger. This is not cart mass.\n');
fprintf('Keep raw data unchanged. Force in N; time in seconds.\n');
folder = uigetdir(pwd,'Choose where to save spring results');
if isequal(folder,0), results=[]; return; end
out = fullfile(folder,['Lab4_Spring_Results_' datestr(now,'yyyymmdd_HHMMSS')]);
mkdir(out);
n = askNumber('Number of springs / records [4]: ',4);
if n<1 || n~=round(n), error('Enter a positive integer.'); end
results=struct([]);
for j=1:n
    cfg=struct();
    cfg.label=input(sprintf('Spring ID for record %d (e.g. A): ',j),'s');
    if isempty(cfg.label), cfg.label=sprintf('Spring%d',j); end
    cfg.massValue=askNumber('Total hanging mass or weight VALUE: ',[]);
    cfg.massUnit=input('Unit: type g, kg, or N (N means weight force): ','s');
    mode=askNumber('1 = Enter Vernier B; 2 = Import Force-Time CSV/Excel: ',[]);
    if mode==1
        cfg.mode='manual';
        cfg.B=askNumber('Vernier B (positive magnitude): ',[]);
        cfg.frequencyUnit=input('B unit: rad/s or Hz (read the fit equation): ','s');
        cfg.alpha=askNumber('Measured decay alpha [1/s], or 0 for light-damping approximation [0]: ',0);
    elseif mode==2
        cfg.mode='file';
        [fn,fp]=uigetfile({'*.csv;*.txt;*.xlsx;*.xls','Vernier Force-Time export'},'Select ONE hanging-spring record');
        if isequal(fn,0), error('No data file selected.'); end
        cfg.file=fullfile(fp,fn);
        opts=detectImportOptions(cfg.file,'VariableNamingRule','preserve');
    T=readtable(cfg.file,opts);numeric=varfun(@isnumeric,T,'OutputFormat','uniform');
    T=T(:,numeric);data=table2array(T);names=T.Properties.VariableNames;
    if size(data,2)<2,error('Need numeric Time and Force columns.');end
        fprintf('\nNumeric columns available:\n');
        for z=1:size(data,2), fprintf('%d: %s\n',z,names{z}); end
        cfg.timeColumn=askNumber('TIME column number (seconds): ',[]);
        cfg.forceColumn=askNumber('FORCE column number (newtons): ',[]);
        tc=cfg.timeColumn;fc=cfg.forceColumn;
        if tc~=round(tc)||fc~=round(fc)||tc<1||fc<1||tc>size(data,2)||fc>size(data,2)||tc==fc
            error('Choose different valid numeric Time and Force column numbers.');
        end
        tt=data(:,tc);ff=data(:,fc);
        figure('Color','w');plot(tt,ff,'.-');grid on;
        xlabel('Time in exported file (s)');ylabel('Force (N)');
        title('Choose clean vertical free motion AFTER release; exclude hand contact');
        cfg.startTime=askNumber('Fit START time in exported seconds: ',[]);
        cfg.endTime=askNumber('Fit END time in exported seconds: ',[]);
        fitMode=askNumber('1 = ordinary sine (weak decay); 2 = damped sine [2]: ',2);
        if ~ismember(fitMode,[1 2]), error('Choose 1 or 2.'); end
        cfg.damped=(fitMode==2);
        fprintf('Optional frequency search band in Hz; leave blank for automatic.\n');
        band=input('Band [minimum maximum] Hz, or Enter: ');
        if ~isempty(band), cfg.frequencyBand=band; end
    else
        error('Choose mode 1 or 2.');
    end
    cfg.outputDir=out;cfg.makePlots=true;
    r=Lab4_Spring_Stiffness_Analysis(cfg);results(j)=r;
    writeSummary(fullfile(out,'Spring_Stiffness_Summary.csv'),results);
    fprintf('\n%s: mass=%.6g kg, B=%.6g rad/s, f=%.6g Hz, k=%.6g N/m\n',r.label,r.mass_kg,r.B_rad_s,r.frequency_Hz,r.k_N_m);
    fprintf('Quality note: %s\n',r.qualityNote);
end
fprintf('\nSaved summary and fit evidence to:\n%s\n',out);
fprintf('Use the individual k values as kLeft/kRight in the separate CART script.\n');

end

function x=askNumber(prompt,default)
x=input(prompt);if isempty(x)&&~isempty(default),x=default;end
if ~isnumeric(x)||~isscalar(x)||~isfinite(x),error('Enter one finite numeric value.');end
end
function writeSummary(file,r)
fid=fopen(file,'w');if fid<0,error('Cannot write summary CSV.');end
fprintf(fid,'Spring_ID,Mode,Hanging_mass_kg,B_rad_s,Frequency_Hz,Alpha_s_inv,k_light_N_m,k_used_N_m,R2,RMSE_N,Cycles,Samples_per_cycle,Start_time_s,End_time_s,Source,Quality_note\n');
for i=1:numel(r)
 q=r(i);nums=[q.mass_kg q.B_rad_s q.frequency_Hz q.alpha_s_inv q.k_light_N_m q.k_N_m q.R2 q.RMSE_N q.cycles q.samplesPerCycle q.startTime_s q.endTime_s];
 fprintf(fid,'"%s","%s",',csv(q.label),csv(q.mode));fprintf(fid,'%.12g,',nums);
 fprintf(fid,'"%s","%s"\n',csv(q.source),csv(q.qualityNote));
end
fclose(fid);
end
function s=csv(s)
s=strrep(s,'"','""');s=strrep(s,sprintf('\n'),' ');
end
