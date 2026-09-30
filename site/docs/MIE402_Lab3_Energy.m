function E = MIE402_Lab3_Energy(y,p)
% y rows [theta1;omega1;theta2;omega2], columns are times.
I11=(p.m1/3+p.M1+p.m2+p.M2)*p.L1^2;
I22=(p.m2/3+p.M2)*p.L2^2;
C=(p.m2/2+p.M2)*p.L1*p.L2;
G1=(p.m1/2+p.M1+p.m2+p.M2)*p.g*p.L1;
G2=(p.m2/2+p.M2)*p.g*p.L2;
a=y(1,:); w=y(2,:); b=y(3,:); v=y(4,:);
E=.5*I11*w.^2+.5*I22*v.^2+C*cos(a-b).*w.*v ...
  +G1*(1-cos(a))+G2*(1-cos(b));
end
