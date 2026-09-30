%% RUN THIS SCRIPT (not the helper function files).
% MIE 402 Lab 3 — baseline two-link compound-pendulum prediction.
% Replace the example values with masses/lengths measured for YOUR setup.
% Units: kg, m, s, radians internally. Release angles below are degrees.
clear; close all; clc
p.g=9.81;
p.L1=0.17; p.L2=0.13;       % pivot-to-joint, joint-to-lower-bob center
p.m1=0.010; p.m2=0.008;     % upper and lower uniform bar masses
p.M1=0.040; p.M2=0.030;     % upper joint/bob and lower bob/hardware masses
theta1_0_deg=5; theta2_0_deg=5;
omega1_0=0; omega2_0=0;   % release from rest unless measured otherwise
duration_s=8;

assert(all(structfun(@(v)isnumeric(v)&&isscalar(v)&&isfinite(v),p)), ...
    'All physical parameters must be finite scalars.');
assert(all([p.L1,p.L2,p.M1,p.M2]>0) && all([p.m1,p.m2]>=0), ...
    'Lengths and bob masses must be positive; bar masses cannot be negative.');
y0=[deg2rad(theta1_0_deg);omega1_0;deg2rad(theta2_0_deg);omega2_0];
opts=odeset('RelTol',1e-9,'AbsTol',1e-11);
tout=linspace(0,duration_s,max(1001,round(duration_s*200)+1));
[t,y]=ode45(@(t,y)MIE402_Lab3_RHS(t,y,p),tout,y0,opts);
E=MIE402_Lab3_Energy(y.',p);
fprintf('Maximum relative energy drift (undamped numerical model): %.3g\n', ...
    max(abs(E-E(1)))/max(E(1),eps));
figure('Name','Lab 3 baseline simulation');
tiledlayout(2,2);
nexttile;plot(t,rad2deg(y(:,1)),t,rad2deg(y(:,3)));grid on
xlabel('Time (s)');ylabel('Angle (deg)');legend('\theta_1','\theta_2');title('Angles');
nexttile;plot(t,y(:,2),t,y(:,4));grid on
xlabel('Time (s)');ylabel('Angular velocity (rad/s)');legend('\omega_1','\omega_2');title('Velocities');
nexttile;plot(t,E);grid on;xlabel('Time (s)');ylabel('Energy (J)');title('Energy check');
nexttile;plot(rad2deg(y(:,1)),rad2deg(y(:,3)));grid on
xlabel('\theta_1 (deg)');ylabel('\theta_2 (deg)');title('Coupled trajectory');
disp('Run_Lab3_Simulation is a script. Do not press Run in MIE402_Lab3_RHS.m.');
