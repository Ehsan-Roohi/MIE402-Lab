% Numerical engine for Run_Lab4_Spring_Stiffness.m.
% Students run the Run_... script; this function requires a configuration.

function r=Lab4_Spring_Stiffness_Analysis(c)
required(c,{'massValue','massUnit','mode'});
m=toMass(c.massValue,c.massUnit);
label=getfieldDefault(c,'label','Spring');
if ~ischar(label), error('Spring label must be text.'); end
r=struct('label',label,'mode',c.mode,'mass_kg',m,'B_rad_s',NaN, ...
 'frequency_Hz',NaN,'alpha_s_inv',NaN,'k_light_N_m',NaN,'k_N_m',NaN, ...
 'R2',NaN,'RMSE_N',NaN,'cycles',NaN,'samplesPerCycle',NaN, ...
 'startTime_s',NaN,'endTime_s',NaN,'qualityNote','','source','manual B', ...
 'time_s',[],'force_N',[],'fit_N',[],'residual_N',[]);
if strcmpi(c.mode,'manual')
    required(c,{'B','frequencyUnit'});positive(c.B,'B');
    if strcmpi(strtrim(c.frequencyUnit),'Hz'), b=2*pi*c.B;
    elseif strcmpi(strtrim(c.frequencyUnit),'rad/s'), b=c.B;
    else, error('Specify frequencyUnit as rad/s or Hz.'); end
    alpha=getfieldDefault(c,'alpha',0);nonnegative(alpha,'alpha');
    r.qualityNote='Manual B: no raw waveform fit verified; retain Vernier fit screenshot.';
elseif strcmpi(c.mode,'file') || strcmpi(c.mode,'data')
    if strcmpi(c.mode,'file')
        required(c,{'file','timeColumn','forceColumn'});
        [a,~]=loadExport(c.file);[t,y]=selectColumns(a,c.timeColumn,c.forceColumn);r.source=c.file;
    else
        required(c,{'time','force'});t=c.time(:);y=c.force(:);r.source='provided force-time arrays';
    end
    if numel(t)~=numel(y),error('Time and force must have the same length.');end
    valid=isfinite(t)&isfinite(y);t=t(valid);y=y(valid);
    if numel(t)<30,error('Need at least 30 finite force-time samples.');end
    if any(diff(t)<=0),error('Timestamps must increase strictly. Select one run; do not combine runs.');end
    lo=getfieldDefault(c,'startTime',t(1));hi=getfieldDefault(c,'endTime',t(end));
    if ~isscalar(lo)||~isscalar(hi)||~isfinite(lo)||~isfinite(hi)||lo>=hi,error('Invalid fit time interval.');end
    use=t>=lo&t<=hi;t=t(use);y=y(use);
    if numel(t)<30,error('Selected interval needs at least 30 samples.');end
    r.startTime_s=t(1);r.endTime_s=t(end);t=t-t(1);
    span=t(end);dt=median(diff(t));fs=1/dt;
    if max(abs(diff(t)-dt))>0.05*dt,error('Time gaps/nonuniform sampling exceed 5%%. Inspect the raw export first.');end
    yrange=max(y)-min(y);
    if yrange <= 1e-10*max(1,max(abs(y))),error('Flat force signal; no frequency can be measured.');end
    band=getfieldDefault(c,'frequencyBand',[2/span 0.40*fs]);
    if numel(band)~=2||any(~isfinite(band))||band(1)<=0||band(1)>=band(2)||band(2)>=fs/2
        error('Frequency band must satisfy 0 < minimum < maximum < Nyquist fs/2.');
    end
    damped=getfieldDefault(c,'damped',true);
    % Fit raw force, including a constant offset. Do not infer mass from offset.
    % Variable projection solves amplitudes/offset linearly at each frequency.
    yy=(y-mean(y))/yrange;
    step=1/(8*span);ngrid=min(12000,max(80,ceil(diff(band)/step)+1));
    grid=linspace(band(1),band(2),ngrid);score=zeros(size(grid));
    for z=1:numel(grid),score(z)=objective([2*pi*grid(z),0],t,yy,band,false,span);end
    [~,ix]=sort(score);best=Inf;bestp=[];
    opts=optimset('Display','off','MaxIter',1200,'MaxFunEvals',3000,'TolX',1e-9,'TolFun',1e-11);
    for z=1:min(6,numel(ix))
        seeds=0;if damped,seeds=[0 1/span 3/span];end
        for a=seeds
            if damped
                [p,s]=fminsearch(@(v)objective(v,t,yy,band,true,span),[2*pi*grid(ix(z)),a],opts);
            else
                [q,s]=fminsearch(@(v)objective([v,0],t,yy,band,false,span),2*pi*grid(ix(z)),opts);p=[q,0];
            end
            if s<best,best=s;bestp=p;end
        end
    end
    b=bestp(1);alpha=bestp(2);
    if ~damped,alpha=0;end
    [~,coef,H]=objective([b alpha],t,y,band,damped,span);
    fitted=H*coef;res=y-fitted;R2=1-sum(res.^2)/sum((y-mean(y)).^2);
    cycles=b*span/(2*pi);spp=fs/(b/(2*pi));
    if R2<0.70 || cycles<3
        error('No reliable spring fit: R2=%.3f; %.2f cycles. Select a cleaner/longer interval or narrow the frequency band. No k exported.',R2,cycles);
    end
    notes={};
    if R2<0.95,notes{end+1}='Inspect residuals: R2 below 0.95';end
    if spp<15,notes{end+1}='Fewer than 15 samples/cycle';end
    if alpha*span>3,notes{end+1}='Strong decay: check that late samples are not only noise';end
    if min(abs(b/(2*pi)-band))<0.02*diff(band),notes{end+1}='Frequency near search-band edge';end
    notes{end+1}='Inspect fit and residuals; acceptance checks do not replace physical review';
    r.R2=R2;r.RMSE_N=sqrt(mean(res.^2));r.cycles=cycles;r.samplesPerCycle=spp;
    r.time_s=t;r.force_N=y;r.fit_N=fitted;r.residual_N=res;r.qualityNote=strjoin(notes,'; ');
else
    error('Mode must be manual, file or data.');
end
r.B_rad_s=b;r.frequency_Hz=b/(2*pi);r.alpha_s_inv=alpha;
r.k_light_N_m=m*b*b;r.k_N_m=m*(b*b+alpha*alpha);
if alpha==0
    r.qualityNote=[r.qualityNote ' k=m*B^2 assumes light damping.'];
else
    r.qualityNote=[r.qualityNote ' k=m*(B^2+alpha^2) assumes viscous decay.'];
end
if isfield(c,'outputDir')&&~isempty(c.outputDir)
    if ~exist(c.outputDir,'dir'),mkdir(c.outputDir);end
    safe=regexprep(label,'[^A-Za-z0-9_-]','_');
    if ~isempty(r.time_s)
        fid=fopen(fullfile(c.outputDir,[safe '_Fit_Data.csv']),'w');assert(fid>=0,'Cannot write output.');
        fprintf(fid,'Time_since_fit_start_s,Force_N,Fitted_force_N,Residual_N\n');
        fprintf(fid,'%.12g,%.12g,%.12g,%.12g\n',[r.time_s r.force_N r.fit_N r.residual_N]');fclose(fid);
        if getfieldDefault(c,'makePlots',false)
            f=figure('Color','w');
            subplot(2,1,1);plot(r.time_s,r.force_N,'.','Color',[.25 .25 .25]);hold on;
            plot(r.time_s,r.fit_N,'b-','LineWidth',1.3);grid on;xlabel('Time since fit start (s)');ylabel('Force (N)');
            legend('Measured','Fitted','Location','best');
            title(sprintf('%s: B=%.4g rad/s, f=%.4g Hz, k=%.4g N/m',label,b,r.frequency_Hz,r.k_N_m),'Interpreter','none');
            subplot(2,1,2);plot(r.time_s,r.residual_N,'k-');grid on;xlabel('Time since fit start (s)');ylabel('Residual force (N)');
            title(sprintf('R^2=%.4f, RMSE=%.3g N, alpha=%.3g s^{-1}; m_h=%.4g kg',r.R2,r.RMSE_N,alpha,m));
            print(f,fullfile(c.outputDir,[safe '_Force_Fit.png']),'-dpng','-r180');
            saveas(f,fullfile(c.outputDir,[safe '_Force_Fit.fig']));
        end
    end
    writeSummary(fullfile(c.outputDir,'Spring_Stiffness_Summary.csv'),r);
end
end

function [s,coef,H]=objective(p,t,y,band,damped,span)
b=p(1);a=p(2);coef=[];H=[];
if ~isfinite(b)||~isfinite(a)||b<2*pi*band(1)||b>2*pi*band(2)||a<0||a>10/span||(~damped&&a~=0)
    s=1e30;return;
end
e=exp(-a*t);H=[ones(size(t)),e.*cos(b*t),e.*sin(b*t)];coef=H\y;
s=sum((y-H*coef).^2);
end

function [a,names]=loadExport(file)
[~,~,ext]=fileparts(file);
if exist('OCTAVE_VERSION','builtin')
    if ~ismember(lower(ext),{'.csv','.txt'}),error('Use MATLAB for Excel files, or save the sheet as CSV.');end
    fid=fopen(file,'r');if fid<0,error('Cannot open export.');end
    lines={};while true,l=fgetl(fid);if ~ischar(l),break;end;lines{end+1}=l;end;fclose(fid);
    a=[];names={};sep=',';
    for i=1:numel(lines)
        if sum(lines{i}==sprintf('\t'))>sum(lines{i}==','),sep=sprintf('\t');end
        cells=strsplit(lines{i},sep,'collapsedelimiters',false);v=cellfun(@str2double,cells);
        if sum(isfinite(v))>=2
            if isempty(a),a=nan(0,numel(v));end
            if numel(v)==size(a,2),a(end+1,:)=v;end
        elseif isempty(a)&&numel(cells)>=2,names=cells;
        end
    end
    if isempty(a),error('No numeric Time/Force data found.');end
    if numel(names)~=size(a,2),names=arrayfun(@(n)sprintf('Column %d',n),1:size(a,2),'UniformOutput',false);end
else
    % MATLAB's import options handle standard Vernier metadata/header rows.
    opts=detectImportOptions(file,'VariableNamingRule','preserve');T=readtable(file,opts);
    num=varfun(@isnumeric,T,'OutputFormat','uniform');T=T(:,num);
    if width(T)<2,error('Need numeric time and force columns. Export one run as CSV.');end
    a=table2array(T);names=T.Properties.VariableNames;
end
end
function [t,y]=selectColumns(a,tc,fc)
if ~isscalar(tc)||~isscalar(fc)||tc~=round(tc)||fc~=round(fc)||tc<1||fc<1||tc>size(a,2)||fc>size(a,2)||tc==fc
    error('Choose different valid numeric Time and Force column numbers.');
end
t=a(:,tc);y=a(:,fc);
end
function m=toMass(v,u)
positive(v,'hanging mass / weight');
switch lower(strtrim(u))
 case 'kg',m=v;
 case 'g',m=v/1000;
 case 'n',m=v/9.81;
 otherwise,error('Mass unit must be g, kg or N. N is weight force, converted using g=9.81.');
end
end
function positive(v,n)
if ~isnumeric(v)||~isscalar(v)||~isfinite(v)||v<=0,error('%s must be a positive finite number.',n);end
end
function nonnegative(v,n)
if ~isnumeric(v)||~isscalar(v)||~isfinite(v)||v<0,error('%s must be finite and nonnegative.',n);end
end
function required(c,fields)
for i=1:numel(fields),if ~isfield(c,fields{i}),error('Missing setting: %s',fields{i});end;end
end
function v=getfieldDefault(c,n,d)
if isfield(c,n),v=c.(n);else,v=d;end
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
