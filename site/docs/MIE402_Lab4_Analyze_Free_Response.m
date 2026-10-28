%% MIE 402 Lab 4 - Analyze one free-response CSV file
% Fall 2026. Keep the raw CSV unchanged. This script creates an annotated
% time history, log-peak fit, FFT, and a one-row summary CSV.
clear; close all; clc;

[fileName, folderName] = uigetfile({'*.csv','CSV data (*.csv)'}, ...
    'Select one Vernier cart free-response CSV');
if isequal(fileName,0), error('No file selected.'); end
filePath = fullfile(folderName,fileName);

%% Enter metadata from the laboratory notebook
m = input('Total moving mass m [kg], including all attached moving parts: ');
kLeft = input('Left spring stiffness k_L [N/m]: ');
kRight = input('Right spring stiffness k_R [N/m]: ');
damperCount = input('Number of brake MAGNETS (0, 2, or 4): ');
if ~isscalar(m) || ~isfinite(m) || m<=0 || any(~isfinite([kLeft,kRight])) || any([kLeft,kRight]<=0)
    error('Mass and both spring stiffnesses must be finite and positive.');
end
k = kLeft + kRight;

%% Import time and position
opts = detectImportOptions(filePath,'VariableNamingRule','preserve');
T = readtable(filePath,opts);
numericMask = varfun(@isnumeric,T,'OutputFormat','uniform');
N = T(:,numericMask);
if width(N) < 2
    error('The CSV must contain at least two numeric columns: time and position.');
end
names = lower(string(N.Properties.VariableNames));
timeCol = find(contains(names,'time'),1);
posCol = find(contains(names,'position') | contains(names,'distance'),1);
if isempty(timeCol), timeCol = 1; end
if isempty(posCol), posCol = find((1:width(N))~=timeCol,1); end
t = N{:,timeCol}; xRaw = N{:,posCol};
valid = isfinite(t) & isfinite(xRaw);
t = t(valid); xRaw = xRaw(valid);
[t,order] = sort(t); xRaw = xRaw(order);
[t,uniqueIndex] = unique(t,'stable'); xRaw = xRaw(uniqueIndex);
t = t-t(1);
if numel(t)<20, error('Too few samples in the selected CSV.'); end

%% Select the free response, then subtract equilibrium (do NOT detrend blindly)
fprintf('Recording duration: %.3f s. Enter a free-response interval after release.\n',t(end));
tStart = input('Free-response start time [s], measured from CSV start (0 for all): ');
tEnd = input('Free-response end time [s], measured from CSV start: ');
if isempty(tStart), tStart=0; end
if isempty(tEnd), tEnd=t(end); end
selected=(t>=tStart)&(t<=tEnd); t=t(selected); xRaw=xRaw(selected);
if numel(t)<20, error('Selected response has fewer than 20 samples.'); end
t=t-t(1);
unitChoice=input('Position units in CSV: 1 = m, 2 = cm, 3 = mm: ');
if unitChoice==1, scale=1; elseif unitChoice==2, scale=0.01; elseif unitChoice==3, scale=0.001;
else, error('Choose 1, 2 or 3 for the exported position unit.'); end
xRaw=scale*xRaw;
tailCount=max(5,round(0.10*numel(xRaw)));
xEq=median(xRaw(end-tailCount+1:end));
x=xRaw-xEq; % Offset only; inspect any drift rather than automatically removing it
increments=diff(t); dt=median(increments); fs=1/dt;
if any(increments<=0), error('Non-increasing timestamps.'); end
if max(abs(increments-dt))>0.05*dt
    error('Nonuniform time samples (>5%% variation): inspect export/resample before FFT.');
end

%% Find positive peaks without requiring Signal Processing Toolbox
candidate = find(x(2:end-1)>x(1:end-2) & x(2:end-1)>=x(3:end))+1;
ampThreshold = 0.08*max(abs(x));
candidate = candidate(x(candidate)>ampThreshold);
if numel(candidate)<3
    error(['Fewer than three reliable positive peaks were found. ', ...
        'Check the selected record, offset removal, and release quality.']);
end
% Estimate period, then enforce a minimum separation of 60%% of one cycle.
roughPeriods = diff(t(candidate));
roughPeriod = median(roughPeriods(roughPeriods>0));
if ~isfinite(roughPeriod) || roughPeriod<=0, error('Cannot estimate peak spacing.'); end
minSeparation = 0.60*roughPeriod;
keep = candidate(1);
for q = 2:numel(candidate)
    if t(candidate(q))-t(keep(end)) >= minSeparation
        keep(end+1,1) = candidate(q); %#ok<SAGROW>
    elseif x(candidate(q)) > x(keep(end))
        keep(end) = candidate(q);
    end
end
peakIndex = keep(:); tp = t(peakIndex); xp = x(peakIndex);
if numel(tp)<3, error('Peak filtering left fewer than three peaks.'); end

%% Frequency and damping from time-domain peaks
Td = (tp(end)-tp(1))/(numel(tp)-1); fdTime = 1/Td; omegaD = 2*pi*fdTime;
p = polyfit(tp,log(xp/1),1); % 1 m reference makes log argument dimensionless
alpha = -p(1); logFit = polyval(p,tp);
SSres = sum((log(xp)-logFit).^2);
SStot = sum((log(xp)-mean(log(xp))).^2);
R2 = 1-SSres/SStot;
if alpha<=0, warning('Nonpositive fitted decay: inspect offset, peaks and model.'); end
omegaN = sqrt(omegaD^2+alpha^2);
fn = omegaN/(2*pi);
zeta = alpha/omegaN;
c = 2*m*alpha;
fnTheory = (1/(2*pi))*sqrt(k/m);

%% One-sided displacement spectrum - keep displacement units
Nfft = numel(x);
X = fft(x);
amp = abs(X/Nfft);
amp = amp(1:floor(Nfft/2)+1);
if numel(amp)>2, amp(2:end-1)=2*amp(2:end-1); end
f = fs*(0:floor(Nfft/2))/Nfft;
search = f>0.05 & f<min(5,0.45*fs);
if ~any(search), error('FFT search band empty: inspect sampling and duration.'); end
[~,localMax] = max(amp(search));
searchIndex = find(search); fftIndex = searchIndex(localMax);
fFFT = f(fftIndex);

%% Fit entire damped sinusoid with time-domain linear least squares at estimated alpha and omegaD
% This is an independent fit check; do not infer damping from FFT height.
E=exp(-alpha*t);
Phi=[E.*cos(omegaD*t), E.*sin(omegaD*t), ones(size(t))];
beta=Phi\x; xFit=Phi*beta;
residual=x-xFit;
rmsResidual=sqrt(mean(residual.^2));
relativeResidual=rmsResidual/max(max(abs(x)),eps);

%% Figures
resultFolder = fullfile(folderName,'Lab4_results');
if ~exist(resultFolder,'dir'), mkdir(resultFolder); end
[~,stem] = fileparts(fileName);

fig1 = figure('Color','w','Position',[80 80 1150 720]);
tiledlayout(3,1,'TileSpacing','compact');
nexttile;
plot(t,x,'LineWidth',1.2); hold on;
plot(tp,xp,'o','MarkerFaceColor',[0.55 0.11 0.11]);
plot(t,exp(p(2)-alpha*t),'--','LineWidth',1.5);
plot(t,xFit,':','LineWidth',1.6);
grid on; xlabel('Time (s)'); ylabel('Displacement (m)');
title('Free response, selected positive peaks, and fitted envelope');
legend('equilibrium-centered response','selected peaks','fitted positive-peak decay','full-response fit','Location','best');
nexttile;
plot(tp,log(xp),'o','MarkerFaceColor',[0.16 0.43 0.72]); hold on;
plot(tp,logFit,'-','LineWidth',1.5); grid on;
xlabel('Peak time (s)'); ylabel('ln(peak displacement / 1 m)');
title(sprintf('Log-peak fit: alpha = %.4f 1/s, zeta = %.4f, R^2 = %.4f',alpha,zeta,R2));
nexttile; plot(t,residual); grid on;
xlabel('Time (s)'); ylabel('Fit residual (m)');
title(sprintf('Full-response residual: RMS %.4g m (%.2f%% of max amplitude)',rmsResidual,100*relativeResidual));
exportgraphics(fig1,fullfile(resultFolder,[stem '_time_and_decay.png']),'Resolution',220);

fig2 = figure('Color','w','Position',[120 120 1050 520]);
plot(f,amp,'LineWidth',1.2); hold on;
xline(fFFT,'--','FFT peak','LineWidth',1.4);
xline(fdTime,':','peak-spacing estimate','LineWidth',1.4);
xlim([0 min(5,0.45*fs)]); grid on;
xlabel('Frequency (Hz)'); ylabel('One-sided displacement amplitude (m)');
title(sprintf('Displacement spectrum: FFT peak = %.4f Hz',fFFT));
exportgraphics(fig2,fullfile(resultFolder,[stem '_FFT.png']),'Resolution',220);

%% Save one-row summary
summary = table(string(fileName),m,kLeft,kRight,k,damperCount,fs,t(end), ...
    fdTime,fFFT,fn,zeta,alpha,c,R2,fnTheory,rmsResidual,relativeResidual, ...
    'VariableNames',{'File','Mass_kg','kLeft_Npm','kRight_Npm','kEq_Npm', ...
    'DamperCount','SampleRate_Hz','Duration_s','fd_Time_Hz','f_FFT_Hz', ...
    'fn_Measured_Hz','Zeta','Alpha_per_s','c_Ns_per_m','LogFit_R2', ...
    'fn_Theory_Hz','Residual_RMS_m','Residual_RMS_rel'});
writetable(summary,fullfile(resultFolder,[stem '_summary.csv']));
disp(summary);
fprintf('\nSaved figures and summary in:\n%s\n',resultFolder);

