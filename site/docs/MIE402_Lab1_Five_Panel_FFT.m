%% RUN THIS SCRIPT to make one five-panel FFT figure for ONE sound source.
% Select your five Moku MAT files in this exact order when prompted:
% 100f, 10f, 3f, 1.4f, 1f. Run again for each of the three sound sources.
% No waveform figure is required in the Lab 1 report clarification.
close all; clear; clc
sourceName = input('Sound source (e.g., tuning fork, whistle, snap): ', 's');
if isempty(strtrim(sourceName))
    error('Enter the sound source so the figure can be identified.');
end
caseNames = {'100f','10f','3f','1.4f','1f'};
fig = figure('Color','w','Units','pixels','Position',[100 100 2100 530]);
layout = tiledlayout(fig,1,5,'TileSpacing','compact','Padding','compact');
fprintf('\n%-7s %-16s %-16s %s\n','Case','Achieved fs (Hz)','Peak (Hz)','File');
for k = 1:5
    [fileName, folderName] = uigetfile('*.mat', ...
        sprintf('Select %s MAT file for %s',caseNames{k},sourceName));
    if isequal(fileName,0)
        error('Selection cancelled at %s. Rerun this script for a complete figure.',caseNames{k});
    end
    raw = load(fullfile(folderName,fileName));
    if ~isfield(raw,'moku') || ~isfield(raw.moku,'data') || size(raw.moku.data,2)<2
        error('%s does not have expected moku.data columns [time, voltage].',fileName);
    end
    data = double(raw.moku.data);
    t = data(:,1); x = data(:,2);
    valid = isfinite(t) & isfinite(x);
    t = t(valid); x = x(valid);
    if numel(t)<3 || any(diff(t)<=0)
        error('%s has too few valid samples or nonincreasing time.',fileName);
    end
    dt = median(diff(t)); fs = 1/dt; N = numel(x);
    if max(abs(diff(t)-dt))>0.02*dt
        warning('%s has uneven time spacing; inspect the MAT export.',fileName);
    end
    Y = fft(x-mean(x));
    A = abs(Y/N);
    A = A(1:floor(N/2)+1);
    if numel(A)>2, A(2:end-1)=2*A(2:end-1); end
    f = fs*(0:floor(N/2))/N;
    A(1)=0; % exclude the DC bin from the reported sound-frequency peak
    [peakAmp,idx]=max(A);
    peakHz=f(idx);
    nexttile(layout,k);
    plot(f,A,'Color',[0.10 0.30 0.55],'LineWidth',1.1); hold on
    plot(peakHz,peakAmp,'ro','MarkerFaceColor','r','MarkerSize',6);
    xlim([0 fs/2]); grid on
    title({sprintf('(%c) %s',char('a'+k-1),caseNames{k}), ...
           sprintf('achieved f_s = %.4g Hz',fs)},'FontSize',11);
    xlabel('Frequency (Hz)');
    if k==1, ylabel('One-sided amplitude (V)'); end
    text(0.98,0.95,sprintf('Measured peak\n%.3f Hz',peakHz), ...
        'Units','normalized','HorizontalAlignment','right', ...
        'VerticalAlignment','top','FontWeight','bold','BackgroundColor','w');
    fprintf('%-7s %-16.6g %-16.6g %s\n',caseNames{k},fs,peakHz,fileName);
end
sgtitle(layout,sprintf('%s: five sampling-rate spectra (measured MATLAB data)',sourceName), ...
    'FontSize',15,'FontWeight','bold');
safeName=regexprep(lower(strtrim(sourceName)),'[^a-z0-9]+','_');
outFile=fullfile(pwd,['Lab1_FFT_',safeName,'_five_panels.png']);
exportgraphics(fig,outFile,'Resolution',300);
fprintf('\nSaved figure: %s\n',outFile);
disp('Review all five peaks. A snap can be broadband: its largest bin is not a single physical tone.');
