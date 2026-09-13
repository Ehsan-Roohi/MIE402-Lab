%% MIE 402 Lab 1 - Plot, analyze, and replay a recorded sound
% All analysis commands are supplied. Students only select their MAT file,
% run each section, save the figures, and interpret the results.

close all; clear; clc;

%% 1. Select and load one Moku:Go MATLAB file
[fileName, folderName] = uigetfile('*.mat', 'Select a Lab 1 MAT file');
if isequal(fileName, 0)
    error('No MAT file was selected.');
end
filePath = fullfile(folderName, fileName);
expData = load(filePath);

% A standard Moku:Go export stores time in column 1 and input voltage in
% column 2. If your file uses another structure, ask your GTA before editing.
if ~isfield(expData, 'moku') || ~isfield(expData.moku, 'data')
    error('This file does not contain expData.moku.data. Confirm the Moku export format with your GTA.');
end
data = expData.moku.data;
if size(data, 2) < 2
    error('The data array must contain time in column 1 and voltage in column 2.');
end
t = data(:,1);
x = data(:,2);
valid = isfinite(t) & isfinite(x);
t = t(valid);
x = x(valid);
if numel(t) < 3
    error('The selected file does not contain enough valid samples.');
end

%% 2. Recover the achieved sampling information from the time column
dt = median(diff(t));
fs = 1/dt;
N = numel(x);
recordDuration = N/fs;
fprintf('\nFile: %s\n', fileName);
fprintf('Samples, N: %d\n', N);
fprintf('Median sample interval: %.9g s\n', dt);
fprintf('Achieved sample rate: %.6g samples/s\n', fs);
fprintf('DFT record duration, N/fs: %.6g s\n', recordDuration);
fprintf('Mean voltage: %.6g V\n', mean(x));
fprintf('RMS voltage: %.6g V\n', sqrt(mean(x.^2)));

%% 3. Plot the recorded waveform
% Display at most the first 100 ms so individual cycles/samples are visible.
displayEnd = min(t(1) + 0.100, t(end));
keep = t <= displayEnd;
figure('Color','w');
plot(1000*(t(keep)-t(1)), x(keep), 'o-', 'LineWidth', 1.1, 'MarkerSize', 3);
xlabel('Time from start (ms)');
ylabel('Microphone voltage (V)');
title(sprintf('%s: waveform, f_s = %.4g samples/s', fileName, fs), 'Interpreter','none');
grid on;

%% 4. Calculate and plot the one-sided amplitude spectrum
% Remove the mean so that DC does not hide sound-frequency peaks. Report the
% original mean separately using the value printed above.
xFFT = x - mean(x);
Y = fft(xFFT);
P2 = abs(Y/N);
P1 = P2(1:floor(N/2)+1);
if numel(P1) > 2
    P1(2:end-1) = 2*P1(2:end-1);
end
f = fs*(0:floor(N/2))/N;
[peakAmplitude, peakIndex] = max(P1);
peakFrequency = f(peakIndex);
fprintf('Strongest non-DC FFT bin: %.6g Hz, amplitude %.6g V\n', peakFrequency, peakAmplitude);
fprintf('FFT-bin spacing: %.6g Hz\n', fs/N);

figure('Color','w');
plot(f, P1, 'LineWidth', 1.2);
hold on;
plot(peakFrequency, peakAmplitude, 'ro', 'MarkerFaceColor','r');
xlabel('Frequency (Hz)');
ylabel('One-sided amplitude (V)');
title(sprintf('%s: amplitude spectrum', fileName), 'Interpreter','none');
xlim([0 fs/2]);
grid on;

%% 5. Replay for listening only
% Playback must use the measured sample rate. Many sound cards cannot play
% rates below about 8 kHz, so create a listening copy at an accepted rate.
% This interpolation does not restore information lost during acquisition.
playbackFs = max(8000, round(fs));
if playbackFs == round(fs)
    xPlay = x;
else
    tPlay = (0:1/playbackFs:(recordDuration-1/playbackFs))';
    xPlay = interp1(t-t(1), x, tPlay, 'linear', 0);
end
xPlay = xPlay - mean(xPlay);
peak = max(abs(xPlay));
if peak > 0
    xPlay = 0.90*xPlay/peak; % prevent clipping while preserving waveform shape
end
fprintf('Playing a listening copy at %.0f samples/s for %.3f s.\n', playbackFs, numel(xPlay)/playbackFs);
sound(xPlay, playbackFs);

%% 6. Save figures manually with informative names
% Save each figure as a high-resolution PNG or PDF. In the report, state the
% source, requested and achieved sample rates, duration, and trial number.
