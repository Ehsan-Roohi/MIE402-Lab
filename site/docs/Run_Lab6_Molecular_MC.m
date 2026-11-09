% LAB 6 OPTIONAL: MOLECULAR MOMENTUM TRANSFER (base MATLAB).
% Run this script, not the helper. All temperatures below are illustrative.
% This is a wall-collision Monte Carlo, not a full DSMC model or an rpm predictor.
clear; clc;
N=50000; Tgas=300; Thot=330; Tcold=300; diffuseFraction=1; seed=402;
out=fullfile(pwd,'Lab6_Molecular_MC_Results'); if ~exist(out,'dir'),mkdir(out);end
R=Lab6_Molecular_MC(N,Tgas,Thot,Tcold,diffuseFraction,seed);
fprintf('Pressure difference / reservoir pressure: MC %.6g; analytical %.6g\n',R.deltaP_over_p,R.analytic_deltaP_over_p);
fprintf('No measured bulb pressure or vane temperature is assumed. This does not predict apparatus rpm.\n');
% Empirical CDFs show the actual distributions, without histogram bars.
fig=figure('Color','w'); hold on;
plot(sort(R.normal_speed_cold_m_s),(1:N)'/N,'b-');
plot(sort(R.normal_speed_hot_m_s),(1:N)'/N,'r-');
v=linspace(0,max([R.normal_speed_hot_m_s;R.normal_speed_cold_m_s]),400);
if diffuseFraction==1
 plot(v,1-exp(-R.molecule_mass_kg*v.^2/(2*R.kB*Tcold)),'b--');
 plot(v,1-exp(-R.molecule_mass_kg*v.^2/(2*R.kB*Thot)),'r--');
 legend('Cold-face MC','Hot-face MC','Cold-face analytical','Hot-face analytical','Location','southeast');
else,legend('Cold-face MC','Hot-face MC','Location','southeast');end
xlabel('Outgoing normal speed (m/s)');ylabel('Cumulative probability');grid on;
exportgraphics(fig,fullfile(out,'Molecular_Normal_Speeds.png'),'Resolution',250);
exportgraphics(fig,fullfile(out,'Molecular_Normal_Speeds.pdf'),'ContentType','vector');
% Compare three independent seeds with the analytical free-molecular result.
dT=(0:5:60)'; result=zeros(numel(dT),3); theory=zeros(size(dT));
fig=figure('Color','w');hold on;
for j=1:3
 for i=1:numel(dT)
  q=Lab6_Molecular_MC(N,Tgas,Tcold+dT(i),Tcold,diffuseFraction,seed+100*j+i);
  result(i,j)=q.deltaP_over_p;theory(i)=q.analytic_deltaP_over_p;
 end
 plot(dT,result(:,j),'o','DisplayName',sprintf('MC seed series %d',j));
end
plot(dT,theory,'k-','LineWidth',1.5,'DisplayName','Analytical wall-collision model');
xlabel('Hot minus cold wall temperature (K)');ylabel('Pressure difference / reservoir pressure');grid on;legend('Location','northwest');
exportgraphics(fig,fullfile(out,'Molecular_Force_Comparison.png'),'Resolution',250);
exportgraphics(fig,fullfile(out,'Molecular_Force_Comparison.pdf'),'ContentType','vector');
writetable(table(dT,theory,result(:,1),result(:,2),result(:,3),...
 'VariableNames',{'temperature_difference_K','analytical_deltaP_over_p','MC_series1','MC_series2','MC_series3'}),fullfile(out,'Molecular_Force_Comparison.csv'));
% Each convergence curve uses nested prefix averages of one realization.
counts=unique(round(logspace(2,log10(N),35)));fig=figure('Color','w');hold on;
for j=1:3
 q=Lab6_Molecular_MC(N,Tgas,Thot,Tcold,diffuseFraction,seed+j);
 cumulative=cumsum(q.samples_deltaP_over_p);
 semilogx(counts,cumulative(counts)./counts(:),'.-','DisplayName',sprintf('Realization %d',j));
end
yline(R.analytic_deltaP_over_p,'k--','DisplayName','Analytical value');
set(gca,'XScale','log');xlabel('Number of sampled collisions (nested prefixes)');ylabel('Pressure difference / reservoir pressure');grid on;legend('Location','best');
exportgraphics(fig,fullfile(out,'Molecular_Sampling_Convergence.png'),'Resolution',250);
fprintf('Saved figures and temperature-sweep CSV to %s\n',out);
