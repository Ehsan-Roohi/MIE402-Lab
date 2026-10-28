function results = Run_Lab4_Spring_Stiffness()
% Lab 4 - Spring stiffness analysis (vertical hanging-spring test)
% Open THIS file and click Run. No input arguments are required.
% Keep Lab4_Spring_Stiffness_Analysis.m in the same folder.
% This is separate from MIE402_Lab4_Analyze_Free_Response.m (the cart).
% B in F=A*sin(B*t+phase)+offset is rad/s. Include hanger in hanging mass.
fprintf('\nLAB 4 - SPRING STIFFNESS (vertical test, one spring at a time)\n');
fprintf('Use total HANGING mass, including hanger. This is not cart mass.\n');
fprintf('Keep raw data unchanged. Force in N; time in seconds.\n');
out='';
fprintf('Choose the input file when prompted. Results are saved beside the first file.\n');
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
        [fn,fp]=uigetfile({'*.csv;*.txt;*.tsv;*.xlsx;*.xls;*.xlsm','Vernier data (CSV, Excel)';'*.*','All files (*.*)'},'Select the SPRING force-data file');
        if isequal(fn,0), fprintf('No file selected; previous results are saved.\n');return; end
        cfg.file=fullfile(fp,fn);[~,~,ext]=fileparts(cfg.file);cfg.sheet='';
        if ismember(lower(ext),{'.xlsx','.xls','.xlsm'})
            sheets=Lab4_Vernier_Sheets(cfg.file);
            if numel(sheets)>1
                [choice,ok]=listdlg('PromptString','Choose the worksheet containing Time and Force','SelectionMode','single','ListString',sheets);
                if ~ok,fprintf('No worksheet selected; previous results are saved.\n');return;end
                cfg.sheet=sheets{choice};
            else
                cfg.sheet=sheets{1};
            end
        end
        [data,names,cfg.sheet]=Lab4_Read_Vernier_Force(cfg.file,cfg.sheet);
        eligible=find(sum(isfinite(data),1)>=30);
        fprintf('\nColumns in %s:\n',fn);
        for z=eligible, fprintf('%d: %s (%d numeric values)\n',z,names{z},sum(isfinite(data(:,z)))); end
        timeMatches=eligible(~cellfun('isempty',regexpi(names(eligible),'time|zeit|temps')));
        forceMatches=eligible(~cellfun('isempty',regexpi(names(eligible),'force|load')));
        td=[];fd=[];if numel(timeMatches)==1,td=timeMatches;end;if numel(forceMatches)==1,fd=forceMatches;end
        cfg.timeColumn=askNumber('TIME column number (Enter to accept identified column): ',td);
        cfg.forceColumn=askNumber('FORCE column number (Enter to accept identified column): ',fd);
        tc=cfg.timeColumn;fc=cfg.forceColumn;
        if tc~=round(tc)||fc~=round(fc)||tc<1||fc<1||tc>size(data,2)||fc>size(data,2)||tc==fc
            error('Choose different valid Time and Force column numbers.');
        end
        tu=askNumber('Time unit: 1 = seconds, 2 = milliseconds, 3 = minutes [1]: ',1);
        fu=askNumber('Force unit: 1 = N, 2 = mN, 3 = kN [1]: ',1);
        timeFactors=[1 .001 60];forceFactors=[1 .001 1000];
        if ~ismember(tu,1:3)||~ismember(fu,1:3),error('Choose one of the displayed units.');end
        cfg.timeScale=timeFactors(tu);cfg.forceScale=forceFactors(fu);
        tt=data(:,tc);ff=data(:,fc);
        figure('Color','w');plot(tt,ff,'.-');grid on;
        xlabel('Time in selected file (original units)');ylabel('Force in selected file (original units)');
        title('Choose clean vertical free motion AFTER release; exclude hand contact');
        cfg.startTime=askNumber('Fit START time in original file units: ',[]);
        cfg.endTime=askNumber('Fit END time in original file units: ',[]);
        fitMode=askNumber('1 = ordinary sine (weak decay); 2 = damped sine [2]: ',2);
        if ~ismember(fitMode,[1 2]), error('Choose 1 or 2.'); end
        cfg.damped=(fitMode==2);
        fprintf('Optional frequency search band in Hz; leave blank for automatic.\n');
        band=input('Band [minimum maximum] Hz, or Enter: ');
        if ~isempty(band), cfg.frequencyBand=band; end
    else
        error('Choose mode 1 or 2.');
    end
    if isempty(out)
        if strcmpi(cfg.mode,'file'), parent=fileparts(cfg.file); else, parent=pwd; end
        base=fullfile(parent,['Lab4_Spring_Results_' datestr(now,'yyyymmdd_HHMMSS')]);
        out=base;counter=1;while exist(out,'dir'),counter=counter+1;out=[base '_' num2str(counter)];end
        [ok,msg]=mkdir(out);if ~ok,error('Cannot create results folder: %s',msg);end
    end
    cfg.outputDir=out;cfg.makePlots=true;
    r=Lab4_Spring_Stiffness_Analysis(cfg);
    if isempty(results),results=r;else,results(j)=r;end
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
