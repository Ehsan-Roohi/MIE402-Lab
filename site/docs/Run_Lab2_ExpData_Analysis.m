% MIE 402 Lab 2: run this SCRIPT after the Pendulum Motion Analyzer saves
% an ExpData MAT file. Do not click Run inside sineFit.m: it is a function
% that needs the time and angle vectors supplied by this script.

scriptFolder = fileparts(mfilename('fullpath'));
if exist(fullfile(scriptFolder,'sineFit.m'),'file') ~= 2
    error('Lab2:MissingSineFit', ...
        'Keep sineFit.m beside Run_Lab2_ExpData_Analysis.m, then run this script.');
end
addpath(scriptFolder,'-begin');

[matName, matFolder] = uigetfile({'*.mat','MAT files (*.mat)'}, ...
    'Select the ExpData MAT file saved by Pendulum Motion Analyzer');
if isequal(matName,0)
    disp('No MAT file selected. Analyze and save the video first.');
    return
end

loaded = load(fullfile(matFolder,matName));
if ~isfield(loaded,'ExpData')
    error('Lab2:MissingExpData', ...
        'The selected MAT file has no ExpData variable. Use Save Results in the analyzer.');
end
data = loaded.ExpData;
if ~isnumeric(data) || size(data,2) < 3
    error('Lab2:InvalidExpData', ...
        'ExpData must contain at least three columns: time, bob X, bob Y.');
end

% The analyzer saves X and Y in mm relative to the pivot; Y is positive
% upward. Thus the bob hanging vertically below the pivot has theta = 0.
tAll = double(data(:,1));
xAll = double(data(:,2));
yAll = double(data(:,3));
valid = isfinite(tAll) & isfinite(xAll) & isfinite(yAll);
fprintf('Valid tracked frames: %d of %d (%.1f%%).\n', ...
    sum(valid),numel(valid),100*mean(valid));
if any(~isfinite(tAll)) || any(diff(tAll)<=0)
    error('Lab2:InvalidTime','ExpData time must be finite and strictly increasing.');
end
missing = ~valid;
gapEdges = diff([false;missing;false]);
gapStarts = find(gapEdges==1);
gapEnds = find(gapEdges==-1)-1;
if ~isempty(gapStarts)
    longestGapSeconds = max(gapEnds-gapStarts+1)*median(diff(tAll));
else
    longestGapSeconds = 0;
end
fprintf('Longest missing-position gap: %.3f s.\n',longestGapSeconds);
if mean(valid) < 0.90
    error('Lab2:ManyMissingFrames', ...
        ['Only %.1f%% of frames contain valid bob positions. Re-run the app in ', ...
         'Analyze All Frames mode, check contrast/focus, and save a new MAT file. ', ...
         'Do not report a sine fit from this incomplete track.'],100*mean(valid));
end
if longestGapSeconds > 0.05
    error('Lab2:LongTrackingGap', ...
        'A tracking gap is %.3f s; re-track instead of fitting across that gap.',longestGapSeconds);
end
if sum(valid) < 12
    error('Lab2:TooFewFrames','At least 12 valid tracked frames are needed.');
end

t = tAll(valid);
theta = unwrap(atan2(xAll(valid),-yAll(valid)));
if any(diff(t) <= 0)
    error('Lab2:TimeOrder', ...
        'Tracked times must increase. Check the frame-rate setting and MAT file.');
end

% sineFit is a FUNCTION. Supply time and angle; Plot=0 avoids extra windows.
% Its constant-amplitude sine is a frequency estimate, not a model of the
% decaying envelope. A visibly damped trace requires a separate damped fit.
p = sineFit(t,theta,0);
thetaFit = p(1)+p(2)*sin(2*pi*p(3)*t+p(4));
fprintf('Sine-fit frequency = %.4f Hz; period = %.4f s; MSE = %.5g rad^2.\n', ...
    p(3),1/p(3),abs(p(5)));

figure('Name','MIE 402 Lab 2: angle and fitted sinusoid');
plot(t,theta,'k.','MarkerSize',4); hold on
plot(t,thetaFit,'r-','LineWidth',1.5); hold off
xlabel('Time (s)'); ylabel('Angle (rad)');
legend('Tracked angle','Constant-amplitude sine fit','Location','best');
grid on
title(sprintf('Lab 2: fitted frequency %.3f Hz',p(3)));

% At large release angles or with obvious damping, one sine is only an
% approximation. Inspect the overlay before reporting the fitted frequency.
