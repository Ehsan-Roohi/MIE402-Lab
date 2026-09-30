function dydt = MIE402_Lab3_RHS(~,y,p)
% MIE402_Lab3_RHS  Double compound pendulum, absolute angles from downward.
% State y = [theta1; omega1; theta2; omega2] in rad and rad/s.
% m1,m2 are uniform bar masses; M1,M2 are lumped joint/bob masses.
% No damping is included in this baseline model.
th1=y(1); w1=y(2); th2=y(3); w2=y(4);
d=th1-th2;
I11=(p.m1/3+p.M1+p.m2+p.M2)*p.L1^2;
I22=(p.m2/3+p.M2)*p.L2^2;
C=(p.m2/2+p.M2)*p.L1*p.L2;
G1=(p.m1/2+p.M1+p.m2+p.M2)*p.g*p.L1;
G2=(p.m2/2+p.M2)*p.g*p.L2;
A=[I11,C*cos(d);C*cos(d),I22];
b=[-C*sin(d)*w2^2-G1*sin(th1); C*sin(d)*w1^2-G2*sin(th2)];
a=A\b;
dydt=[w1;a(1);w2;a(2)];
end
