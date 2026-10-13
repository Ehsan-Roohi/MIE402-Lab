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
damperCount = input('Number of eddy-current dampers (0, 2, or 4): ');
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

%% Remove the equilibrium offset and any small linear drift
tailCount = max(5,round(0.10*numel(xRaw)));
xCentered = xRaw - mean(xRaw(end-tailCount+1:end));
x = detrend(xCentered,1);
dt = median(diff(t)); fs = 1/dt;

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
Td = mean(diff(tp)); fdTime = 1/Td; omegaD = 2*pi*fdTime;
p = polyfit(tp,log(xp),1);
alpha = -p(1); logFit = polyval(p,tp);
SSres = sum((log(xp)-logFit).^2);
SStot = sum((log(xp)-mean(log(xp))).^2);
R2 = 1-SSres/SStot;
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
[~,localMax] = max(amp(search));
searchIndex = find(search); fftIndex = searchIndex(localMax);
fFFT = f(fftIndex);

%% Figures
resultFolder = fullfile(folderName,'Lab4_results');
if ~exist(resultFolder,'dir'), mkdir(resultFolder); end
[~,stem] = fileparts(fileName);

fig1 = figure('Color','w','Position',[80 80 1150 720]);
tiledlayout(2,1,'TileSpacing','compact');
nexttile;
plot(t,x,'LineWidth',1.2); hold on;
plot(tp,xp,'o','MarkerFaceColor',[0.55 0.11 0.11]);
plot(t,exp(p(2)-alpha*t),'--','LineWidth',1.5);
grid on; xlabel('Time (s)'); ylabel('Displacement (m)');
title('Free response, selected positive peaks, and fitted envelope');
legend('detrended response','selected peaks','fitted envelope','Location','best');
nexttile;
plot(tp,log(xp),'o','MarkerFaceColor',[0.16 0.43 0.72]); hold on;
plot(tp,logFit,'-','LineWidth',1.5); grid on;
xlabel('Peak time (s)'); ylabel('ln(peak displacement / 1 m)');
title(sprintf('Log-peak fit: alpha = %.4f 1/s, zeta = %.4f, R^2 = %.4f',alpha,zeta,R2));
exportgraphics(fig1,fullfile(resultFolder,stem+'_time_and_decay.png'),'Resolution',220);

fig2 = figure('Color','w','Position',[120 120 1050 520]);
plot(f,amp,'LineWidth',1.2); hold on;
xline(fFFT,'--','FFT peak','LineWidth',1.4);
xline(fdTime,':','peak-spacing estimate','LineWidth',1.4);
xlim([0 min(5,0.45*fs)]); grid on;
xlabel('Frequency (Hz)'); ylabel('One-sided displacement amplitude (m)');
title(sprintf('Displacement spectrum: FFT peak = %.4f Hz',fFFT));
exportgraphics(fig2,fullfile(resultFolder,stem+'_FFT.png'),'Resolution',220);

%% Save one-row summary
summary = table(string(fileName),m,kLeft,kRight,k,damperCount,fs,t(end), ...
    fdTime,fFFT,fn,zeta,alpha,c,R2,fnTheory, ...
    'VariableNames',{'File','Mass_kg','kLeft_Npm','kRight_Npm','kEq_Npm', ...
    'DamperCount','SampleRate_Hz','Duration_s','fd_Time_Hz','f_FFT_Hz', ...
    'fn_Measured_Hz','Zeta','Alpha_per_s','c_Ns_per_m','LogFit_R2', ...
    'fn_Theory_Hz'});
writetable(summary,fullfile(resultFolder,stem+'_summary.csv'));
disp(summary);
fprintf('\nSaved figures and summary in:\n%s\n',resultFolder);

