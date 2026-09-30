%% RUN THIS SCRIPT to check the helper files before using measured data.
clear; close all; clc
p=struct('L1',.17,'L2',.13,'m1',.010,'m2',.008, ...
         'M1',.040,'M2',.030,'g',9.81);
y0=[deg2rad(20);0;deg2rad(10);0];
f=MIE402_Lab3_RHS(0,y0,p);
assert(all(isfinite(f)) && numel(f)==4,'RHS returned invalid derivatives.');
[t,y]=ode45(@(t,y)MIE402_Lab3_RHS(t,y,p),linspace(0,8,1601),y0, ...
    odeset('RelTol',1e-10,'AbsTol',1e-12));
E=MIE402_Lab3_Energy(y.',p);
drift=max(abs(E-E(1)))/E(1);
fprintf('Model energy drift over %.1f s = %.3g\n',t(end),drift);
assert(drift<1e-5,'Energy drift is unexpectedly high.');
% Downward vertical in the app's right-positive/up-positive coordinates:
th1=atan2(0,-(-170)); th2=atan2(0-0,-(-300-(-170)));
assert(abs(th1)<1e-12 && abs(th2)<1e-12, ...
    'Angle sign convention failed its vertical-position check.');
disp('Lab 3 model and coordinate self-tests passed.');
