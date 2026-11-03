%% MIE 402 Pre-Lab 5 - impulse, harmonic response and displacement gain
% Run the entire script. Base MATLAB; no Control System Toolbox required.
clear; close all; clc;
m=1; c=1; k=100; F0=1; omega=4*pi; J=1;
% m [kg], c [N*s/m], k [N/m], force F0 [N], omega [rad/s], impulse J [N*s].
wn=sqrt(k/m); alpha=c/(2*m); wd=sqrt(wn^2-alpha^2); zeta=c/(2*sqrt(m*k));
t=(0:.01:20)'; xImpulse=J/(m*wd)*exp(-alpha*t).*sin(wd*t);
Hforce=1/complex(k-m*omega^2,c*omega); phase=atan2(c*omega,k-m*omega^2);
xss=F0*abs(Hforce)*cos(omega*t-phase);
% State vector z=[x;v]; compare full response with steady-state prediction.
ode=@(t,z)[z(2);(F0*cos(omega*t)-c*z(2)-k*z(1))/m];
[~,z]=ode45(ode,t,[.1;0],odeset('RelTol',1e-9,'AbsTol',1e-11));
figure('Color','w');subplot(2,1,1);plot(t,xImpulse);xlabel('Time (s)');ylabel('x (m)');title('Unit impulse J = 1 N s');grid on;
subplot(2,1,2);plot(t,z(:,1),t,xss,'--');xlabel('Time (s)');ylabel('x (m)');legend('Full response','Steady state');grid on;
% Actual laboratory: driven spring end y(t), not a directly applied force.
kFixed=45; kDrive=55; Y=.01; w=logspace(-1,2,400);
H=kDrive./(kFixed+kDrive-m*w.^2+1i*c*w);
figure('Color','w');semilogx(w,20*log10(abs(H)));xlabel('Drive angular frequency (rad/s)');ylabel('Displacement ratio X/Y (dB)');grid on;
% Independent state-space integration check for driven-end input.
wh=4*pi; rhs=@(t,z)[z(2);(kDrive*Y*cos(wh*t)-c*z(2)-(kFixed+kDrive)*z(1))/m];
tt=(0:.01:40)';[~,zz]=ode45(rhs,tt,[0;0],odeset('RelTol',1e-9,'AbsTol',1e-11));
sel=tt>30;A=[cos(wh*tt(sel)),sin(wh*tt(sel)),ones(sum(sel),1)];b=A\zz(sel,1);
numericGain=hypot(b(1),b(2))/Y; theoryGain=abs(kDrive/complex(kFixed+kDrive-m*wh^2,c*wh));
prelab5_numeric=struct('gain',numericGain,'theory',theoryGain,'relative_error',abs(numericGain/theoryGain-1));
fprintf('fn = %.4f Hz; fd = %.4f Hz; damping ratio = %.4f\n',wn/(2*pi),wd/(2*pi),zeta);
fprintf('Force-input steady-state amplitude = %.6f m; lag = %.2f deg\n',F0*abs(Hforce),phase*180/pi);
fprintf('Driven-end ODE/transfer gain relative difference = %.3g\n',prelab5_numeric.relative_error);
