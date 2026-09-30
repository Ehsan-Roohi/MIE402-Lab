%% RUN THIS SCRIPT after Pendulum Motion Analyzer V4 saves an ExpData MAT file.
% Expected columns: time_s, x1_mm, y1_mm, x2_mm, y2_mm.
% x right-positive, y up-positive; all positions relative to fixed pivot.
% The script does not call sineFit: a double pendulum is not one sine wave.
clear; close all; clc
[filename,folder]=uigetfile('*.mat','Select the Lab 3 ExpData MAT file');
if isequal(filename,0), disp('No file selected.'); return; end
S=load(fullfile(folder,filename));
assert(isfield(S,'ExpData'),'Selected MAT file has no ExpData variable.');
D=double(S.ExpData);
assert(size(D,2)>=5 && size(D,1)>=20, ...
    'ExpData needs at least 20 rows and 5 columns: t,x1,y1,x2,y2.');
t=D(:,1); xyz=D(:,2:5);
assert(all(isfinite(t)) && all(diff(t)>0), ...
    'Time must be finite and strictly increasing. Check capture frame rate.');
dt=median(diff(t));
assert(max(abs(diff(t)-dt))<0.02*dt, ...
    'Time spacing is not uniform enough for this FFT. Check ExpData time.');
valid=all(isfinite(xyz),2);
missingFraction=1-mean(valid);
fprintf('Missing/invalid coordinate rows: %.1f%%\n',100*missingFraction);
assert(missingFraction<=0.10,'More than 10%% missing: redo tracking/video.');
assert(nnz(valid)>=20,'Too few valid tracked frames.');
if any(~valid)
    edges=diff([false;~valid;false]); starts=find(edges==1); stops=find(edges==-1)-1;
    longest=max(stops-starts+1);
    assert(longest*dt<=0.05, ...
        'A gap is longer than 0.05 s; inspect/retrack rather than bridging it.');
    assert(valid(1)&&valid(end), ...
        'Start/end frames are missing; trim/retrack before running this script.');
    for col=1:4
        xyz(~valid,col)=interp1(t(valid),xyz(valid,col),t(~valid),'linear');
    end
    disp('Only short internal missing gaps were linearly interpolated.');
end
x1=xyz(:,1);y1=xyz(:,2);x2=xyz(:,3);y2=xyz(:,4);
L1mm=hypot(x1,y1);L2mm=hypot(x2-x1,y2-y1);
theta1=unwrap(atan2(x1,-y1));
theta2=unwrap(atan2(x2-x1,-(y2-y1)));
omega1=gradient(theta1,t);omega2=gradient(theta2,t);
fprintf('Median tracked lengths: L1=%.2f mm, L2=%.2f mm\n', ...
    median(L1mm),median(L2mm));
fprintf('Time spacing %.6g s implies %.2f samples/s. Verify against CAPTURE fps.\n', ...
    dt,1/dt);
fprintf('First angles: theta1=%.2f deg, theta2=%.2f deg. Check a known frame.\n', ...
    rad2deg(theta1(1)),rad2deg(theta2(1)));

N=numel(t); freq=(0:floor(N/2))'/(N*dt);
window=.5-.5*cos(2*pi*(0:N-1)'/(N-1));
z1=fft((theta1-mean(theta1)).*window);
z2=fft((theta2-mean(theta2)).*window);
amp1=2*abs(z1(1:numel(freq)))/sum(window);
amp2=2*abs(z2(1:numel(freq)))/sum(window);
amp1(1)=0;amp2(1)=0;
figure('Name',['Lab 3: ',filename]);tiledlayout(3,1);
nexttile;plot(t,rad2deg(theta1),t,rad2deg(theta2));grid on
xlabel('Time (s)');ylabel('Angle (deg)');legend('\theta_1','\theta_2');
title('Absolute link angles (not relative angle)');
nexttile;plot(t,omega1,t,omega2);grid on
xlabel('Time (s)');ylabel('Angular velocity (rad/s)');legend('\omega_1','\omega_2');
title('Numerical derivative; inspect spikes and missing frames');
nexttile;plot(freq,amp1,freq,amp2);grid on
xlabel('Frequency (Hz)');ylabel('Angle amplitude (rad)');legend('\theta_1','\theta_2');
xlim([0,min(20,freq(end))]);title('Mean-removed, Hann-windowed one-sided spectra');
disp('Keep the MP4, MAT file, parameters, and figures. Repeat for each required trial.');
