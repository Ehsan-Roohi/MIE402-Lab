function result=Run_Lab3_Compare_Theory(inputFile,cfg)
% Compare Lab 3 measurements with Lecture 04 compound-pendulum theory.
% State = [theta1; omega1; theta2; omega2], absolute angles from down.
% SI model inputs: L1,L2 [m], m1,m2 uniform bars [kg], M1,M2 bobs [kg].
% No parameter fitting, damping fitting, time shifting, or gap fabrication.
% Run without inputs for dialogs, or supply cfg for reproducible batch use.
if nargin<1 || isempty(inputFile)
 [f,pth]=uigetfile('*.mat','Select ExpData MAT or Lab3_Analysis.mat');
 if isequal(f,0),result=[];return;end;inputFile=fullfile(pth,f);
end
if nargin<2,cfg=struct;end
[folder,base]=fileparts(inputFile);if isempty(folder),folder=pwd;end
if ~isfield(cfg,'outputFolder'),cfg.outputFolder=fullfile(folder,[base '_TheoryComparison']);end
out=cfg.outputFolder;if ~exist(out,'dir'),mkdir(out);end
if ~isfield(cfg,'makeFigures'),cfg.makeFigures=true;end
if ~isfield(cfg,'initialWindowSeconds'),cfg.initialWindowSeconds=.025;end
S=load(inputFile);
if isfield(S,'result') && isfield(S.result,'continuous')
 R=S.result;
elseif isfield(S,'ExpData')
 assert(exist('Run_Lab3_ExpData_Analysis','file')~=0,'Keep the supplied analysis file in the same folder.');
 R=Run_Lab3_ExpData_Analysis(inputFile,fullfile(out,'Experimental_analysis'));
else
 error('Select an ExpData MAT or the analysis output Lab3_Analysis.mat. Pixel-only tracker files need physical calibration first.');
end
assert(isfield(R,'observed') && size(R.continuous,2)==2,'Both link angles and quality flags are required.');
t=R.time(:);q=R.continuous;obs=logical(R.observed) & ~logical(R.filled);
assert(size(q,1)==numel(t) && all(isfinite(t)) && all(diff(t)>0),'Invalid time/angle arrays.');
good=all(isfinite(q),2) & all(obs,2);
assert(nnz(good)>=20,'Both joints need observed positions. A wholly missing joint must be retracked from video.');
if ~isfield(cfg,'p')
 refs=R.referenceLengths;
 a=inputdlg({'L1: fixed pivot to upper joint [mm]','L2: upper joint to lower bob [mm]',...
  'm1: uniform upper BAR mass [g]','m2: uniform lower BAR mass [g]',...
  'M1: upper joint/bob plus associated hardware [g]','M2: lower bob plus associated hardware [g]'},...
  'Enter measured model parameters; suggested lengths come from tracked coordinates',[1,85],...
  {num2str(refs(1),8),num2str(refs(2),8),'','','',''});
 if isempty(a),result=[];return;end
 vals=cellfun(@str2double,a)/1000;cfg.p=struct('L1',vals(1),'L2',vals(2),'m1',vals(3),'m2',vals(4),'M1',vals(5),'M2',vals(6),'g',9.81);
 cfg.parametersMeasured=true;cfg.parameterSource='User-entered measured masses; lengths entered/checked against tracked coordinates.';
end
p=cfg.p;if ~isfield(p,'g'),p.g=9.81;end
names={'L1','L2','m1','m2','M1','M2','g'};
for k=1:numel(names),assert(isfield(p,names{k}) && isscalar(p.(names{k})) && isfinite(p.(names{k})),['Missing/invalid parameter: ' names{k}]);end
assert(all([p.L1,p.L2,p.M1,p.M2,p.g]>0) && all([p.m1,p.m2]>=0),'Positive lengths, bob masses and gravity are required; bar masses may be zero only for the point-mass limit.');
if ~isfield(cfg,'parametersMeasured'),cfg.parametersMeasured=false;end
if ~isfield(cfg,'parameterSource'),cfg.parameterSource='Unverified supplied parameters.';end
if cfg.parametersMeasured,label='Measured parameter inputs';else,label='ILLUSTRATIVE: assumed/unverified parameters';end
if ~isfield(cfg,'timeRange')
 preview=figure('Name','Choose a free-motion comparison interval','Color','w');
 v=q*180/pi;v(~obs)=NaN;plot(t,v);grid on;xlabel('Original MAT time (s)');ylabel('Link angle (degrees)');
 title('Choose free motion after hand release; review the original recording');legend('Upper link','Lower link');drawnow;
 a=inputdlg({'Start time in original MAT [s]: choose FREE motion after the hand is removed',...
  'End time in original MAT [s]'},'Choose comparison interval',[1,85],{num2str(t(find(good,1))),num2str(t(find(good,1,'last')))});
 if isempty(a),result=[];return;end;cfg.timeRange=cellfun(@str2double,a)';
 if ishandle(preview),close(preview);end
end
assert(numel(cfg.timeRange)==2 && all(isfinite(cfg.timeRange)) && cfg.timeRange(2)>cfg.timeRange(1),'Enter a valid increasing comparison interval.');
dt=median(diff(t));assert(max(abs(diff(t)-dt))<max(1e-8,.001*dt),'This comparison requires uniform timestamps. Review dropped frames/timing instead of silently retiming the experiment.');
a=find(good & t>=cfg.timeRange(1) & t<=cfg.timeRange(2),1);
assert(~isempty(a),'No common observed start in this interval.');
% Find an observed contiguous initial window; never initialize from a bridge.
nwin=max(5,round(cfg.initialWindowSeconds/dt)+1);
while a+nwin-1<=numel(t) && (~all(good(a:a+nwin-1)) || t(a+nwin-1)>cfg.timeRange(2))
 a=find(good & (1:numel(t))'>a & t<=cfg.timeRange(2),1);
 if isempty(a),break;end
end
assert(~isempty(a) && a+nwin-1<=numel(t) && all(good(a:a+nwin-1)) && t(a+nwin-1)<=cfg.timeRange(2),'No sufficiently long observed initial window. Choose another interval.');
idx=find(t>=t(a) & t<=cfg.timeRange(2));assert(numel(idx)>=32,'Choose at least 32 samples.');
tau=t(idx)-t(a);measured=q(idx,:);
% Use an equivalent downward-reference branch; residuals remain circular.
turnOffset=2*pi*round(q(a,:)/(2*pi));measured=measured-turnOffset;
if isfield(cfg,'initialState')
 y0=cfg.initialState(:);assert(numel(y0)==4 && all(isfinite(y0)),'initialState must be [theta1;omega1;theta2;omega2] in rad/rad/s.');
 initialSource='Explicit supplied initial state; verify against the selected start frame.';
else
 y0=zeros(4,1);u=t(a:a+nwin-1)-t(a);
 for j=1:2
  v=q(a:a+nwin-1,j)-turnOffset(j);coef=[ones(nwin,1),u,u.^2]\v;
  y0(2*j-1)=coef(1);y0(2*j)=coef(2);
 end
 initialSource=sprintf('Local quadratic angle fit over %.6g s at start; only initial angle/speed estimated, no dynamics parameters fitted.',u(end));
end
I11=(p.m1/3+p.M1+p.m2+p.M2)*p.L1^2;I22=(p.m2/3+p.M2)*p.L2^2;
C=(p.m2/2+p.M2)*p.L1*p.L2;
G1=(p.m1/2+p.M1+p.m2+p.M2)*p.g*p.L1;G2=(p.m2/2+p.M2)*p.g*p.L2;
M0=[I11,C;C,I22];K=diag([G1,G2]);assert(all(eig(M0)>0),'The inertia matrix must be positive definite.');
[Phi,D]=eig(K,M0);[wn,order]=sort(sqrt(diag(D)));Phi=Phi(:,order);
for j=1:2,Phi(:,j)=Phi(:,j)/sqrt(Phi(:,j)'*M0*Phi(:,j));if Phi(1,j)<0,Phi(:,j)=-Phi(:,j);end;end
modeShapes=Phi./repmat(max(abs(Phi),[],1),2,1);fn=wn/(2*pi);
% Analytical small-angle solution: M0*qdd + K*q = 0.
r0=Phi'*M0*y0([1,3]);v0=Phi'*M0*y0([2,4]);
modal=cos(tau*wn').*repmat(r0',numel(tau),1)+sin(tau*wn').*repmat((v0./wn)',numel(tau),1);
modalV=-sin(tau*wn').*repmat((wn.*r0)',numel(tau),1)+cos(tau*wn').*repmat(v0',numel(tau),1);
linear=zeros(numel(tau),4);linear(:,[1,3])=modal*Phi';linear(:,[2,4])=modalV*Phi';
opts=odeset('RelTol',1e-9,'AbsTol',1e-11);
[ts,nonlinear]=ode45(@(tt,yy)MIE402_Lab3_RHS(tt,yy,p),tau,y0,opts);
assert(numel(ts)==numel(tau) && max(abs(ts-tau))<1e-9,'ODE output times do not match experimental timestamps.');
En=MIE402_Lab3_Energy(nonlinear',p)';energyDrift=max(abs(En-En(1)))/max(abs(En(1)),eps);
assert(energyDrift<1e-5,'Nonlinear solver energy drift is too large; inspect tolerances/model before comparison.');
observed=obs(idx,:) & isfinite(measured);estimated=R.filled(idx,:);
resN=atan2(sin(measured-nonlinear(:,[1,3])),cos(measured-nonlinear(:,[1,3])))*180/pi;
resL=atan2(sin(measured-linear(:,[1,3])),cos(measured-linear(:,[1,3])))*180/pi;
resN(~observed)=NaN;resL(~observed)=NaN;
rmseN=zeros(1,2);rmseL=rmseN;earlyN=rmseN;earlyL=rmseN;
for j=1:2
 m=observed(:,j);rmseN(j)=sqrt(mean(resN(m,j).^2));rmseL(j)=sqrt(mean(resL(m,j).^2));
 m=m & tau<=1;earlyN(j)=sqrt(mean(resN(m,j).^2));earlyL(j)=sqrt(mean(resL(m,j).^2));
end
% All three spectra use the SAME longest observed interval, sampling and Hann window.
[starts,stops]=runs(all(observed,2));[~,longest]=max(stops-starts+1);fi=starts(longest):stops(longest);
freq=[];amps=[];fftPeaks=[NaN,NaN];binSpacing=NaN;quantity='angle [rad]';
if numel(fi)>=32
 n=numel(fi);binSpacing=1/(n*dt);freq=(0:floor(n/2))'/(n*dt);amps=zeros(numel(freq),2,3);
 sig={measured(fi,:),nonlinear(fi,[1,3]),linear(fi,[1,3])};
 rotation=max(max(sig{1})-min(sig{1}))>2*pi || max(max(sig{2})-min(sig{2}))>2*pi;
 if rotation,quantity='sin(angle) [dimensionless]';for k=1:3,sig{k}=sin(sig{k});end;end
 w=.5-.5*cos(2*pi*(0:n-1)'/(n-1));
 for k=1:3
  for j=1:2
   x=sig{k}(:,j);F=fft((x-mean(x)).*w);z=abs(F(1:numel(freq)))/sum(w);
   if rem(n,2)==0,z(2:end-1)=2*z(2:end-1);else,z(2:end)=2*z(2:end);end
   amps(:,j,k)=z;
  end
 end
 for j=1:2,[~,pk]=max(amps(2:end,j,1));fftPeaks(j)=freq(pk+1);end
end
Eexp=nan(numel(tau),1);m=all(observed,2) & all(isfinite(R.omega(idx,:)),2) & ~any(R.derivativeInfluence(idx,:),2);
states=[measured(:,1),R.omega(idx,1),measured(:,2),R.omega(idx,2)];
Eexp(m)=MIE402_Lab3_Energy(states(m,:)',p)';
result=struct('timeOriginal',t(idx),'timeSinceStart',tau,'measuredAngles',measured,...
 'observed',observed,'estimated',estimated,'nonlinearState',nonlinear,'linearState',linear,...
 'p',p,'M0',M0,'K',K,'modeShapes',modeShapes,'modalFrequencyHz',fn,...
 'initialState',y0,'initialStateSource',initialSource,'parametersMeasured',cfg.parametersMeasured,...
 'parameterSource',cfg.parameterSource,'residualNonlinearDeg',resN,'residualLinearDeg',resL,...
 'rmseNonlinearDeg',rmseN,'rmseLinearDeg',rmseL,'firstSecondRmseNonlinearDeg',earlyN,...
 'firstSecondRmseLinearDeg',earlyL,'frequency',freq,'spectralAmplitude',amps,'fftQuantity',quantity,...
 'fftIntervalOriginal',t(idx(fi([1,end]))),'fftBinSpacingHz',binSpacing,'experimentalPeakHz',fftPeaks,...
 'energyNonlinearJ',En,'energyExperimentalModelJ',Eexp,'solverRelativeEnergyDrift',energyDrift,'outputFolder',out);
save(fullfile(out,'Lab3_Theory_Comparison.mat'),'result','-v7');
writeCSV(fullfile(out,'theory_overlay.csv'),[t(idx),tau,measured*180/pi,nonlinear(:,[1,3])*180/pi,linear(:,[1,3])*180/pi,resN,resL,observed,estimated],...
 'original_time_s,time_since_start_s,experimental_theta1_with_flags_deg,experimental_theta2_with_flags_deg,nonlinear_theta1_deg,nonlinear_theta2_deg,linear_theta1_deg,linear_theta2_deg,circular_error_nonlinear1_deg,circular_error_nonlinear2_deg,circular_error_linear1_deg,circular_error_linear2_deg,link1_observed,link2_observed,link1_estimated,link2_estimated');
writeCSV(fullfile(out,'modal_frequencies_and_shapes.csv'),[(1:2)',fn,modeShapes'], 'mode,small_angle_frequency_hz,normalized_theta1,normalized_theta2');
if ~isempty(freq),writeCSV(fullfile(out,'spectra_same_interval.csv'),[freq,amps(:,:,1),amps(:,:,2),amps(:,:,3)],'frequency_hz,experiment1,experiment2,nonlinear1,nonlinear2,linear1,linear2');end
fid=fopen(fullfile(out,'READ_COMPARISON.txt'),'w');assert(fid>=0,'Cannot write comparison summary.');
fprintf(fid,'%s\nParameter provenance: %s\n',label,cfg.parameterSource);
for k=1:numel(names),fprintf(fid,'%s = %.12g (SI units)\n',names{k},p.(names{k}));end
fprintf(fid,'Original MAT start/end: %.9g / %.9g s\n%s\nInitial state [theta1,w1,theta2,w2] = %.9g %.9g %.9g %.9g (rad,rad/s)\n',t(idx(1)),t(idx(end)),initialSource,y0);
fprintf(fid,'Small-angle modal frequencies: %.9g, %.9g Hz\n',fn);
fprintf(fid,'Observed-only circular RMSE nonlinear: %.6g %.6g deg; linear: %.6g %.6g deg\n',rmseN,rmseL);
fprintf(fid,'First-second observed-only circular RMSE nonlinear: %.6g %.6g deg; linear: %.6g %.6g deg\n',earlyN,earlyL);
fprintf(fid,'Nonlinear numerical energy drift: %.6g\nSpectral quantity: %s\nFFT bin spacing: %.9g Hz\nLargest measured FFT bins: %.9g %.9g Hz\n',energyDrift,quantity,binSpacing,fftPeaks);
fprintf(fid,'Models use the same parameters and initial state. No parameter tuning or time/phase shift is applied. Masses must be measured for a physical validation.\n');
fprintf(fid,'The small-angle model is an approximation near downward equilibrium; its modal frequencies are not automatically large-angle FFT peaks.\n');
fprintf(fid,'The nonlinear baseline omits drag/friction. Its numerical energy conservation does not validate the apparatus model. Experimental model-energy uses differentiated data and the entered masses.\n');
fprintf(fid,'Short-gap estimates can be displayed with separate markers but are excluded from error metrics and FFT selection. Long gaps remain blank.\n');fclose(fid);
if cfg.makeFigures,makePlots(result,label);end
fprintf('%s\nSmall-angle frequencies: %.6f, %.6f Hz\nNonlinear circular RMSE: %.4f, %.4f deg\nSaved: %s\n',label,fn,rmseN,out);
end

function makePlots(r,label)
colors=[0,.35,.65;.75,.2,.05;.4,.2,.65];t=r.timeSinceStart;out=r.outputFolder;
f=figure('Name','Measured and predicted angles','Color','w');
for j=1:2
 subplot(2,1,j);hold on;v=r.measuredAngles(:,j);v(~r.observed(:,j))=NaN;
 plot(t,wrappedPlot(v)*180/pi,'.','Color',colors(1,:),'MarkerSize',4);
 plot(t,wrappedPlot(r.nonlinearState(:,2*j-1))*180/pi,'-','Color',colors(2,:),'LineWidth',1.1);
 plot(t,wrappedPlot(r.linearState(:,2*j-1))*180/pi,'--','Color',colors(3,:),'LineWidth',1);
 q=r.estimated(:,j);
 if any(q),plot(t(q),atan2(sin(r.measuredAngles(q,j)),cos(r.measuredAngles(q,j)))*180/pi,'o','Color',[.5,.5,.5],'MarkerSize',3);end
 grid on;xlabel('Time since selected start (s)');ylabel(sprintf('theta_%d (deg)',j));
 if any(q),lh=legend('Observed','Nonlinear theory','Small-angle theory','Short-gap estimates');else,lh=legend('Observed','Nonlinear theory','Small-angle theory');end;set(lh,'Visible','on');
 plotTitle(label,'Blue dots: observed | red solid: nonlinear | purple dashed: small-angle | gray circles: estimates');
end;savePlots(f,out,'01_angles_theory_overlay');
f=figure('Name','Observed-only angular residuals','Color','w');
for j=1:2
 subplot(2,1,j);plot(t,r.residualNonlinearDeg(:,j),'-','Color',colors(2,:));hold on;plot(t,r.residualLinearDeg(:,j),'--','Color',colors(3,:));grid on;
 xlabel('Time since selected start (s)');ylabel(sprintf('theta_%d circular error (deg)',j));lh=legend('Experiment minus nonlinear','Experiment minus small-angle');set(lh,'Visible','on');
 plotTitle(label,'Red: experiment minus nonlinear | purple dashed: experiment minus small-angle');
end;savePlots(f,out,'02_observed_only_residuals');
if ~isempty(r.frequency)
 f=figure('Name','Spectra on the same observed interval','Color','w');
 for j=1:2
  subplot(2,1,j);hold on;
  for k=1:3,plot(r.frequency,r.spectralAmplitude(:,j,k),'Color',colors(k,:),'LineWidth',1);end
  grid on;xlabel('Frequency (Hz)');ylabel(r.fftQuantity,'Interpreter','none');
  xlim([0,min(r.frequency(end),max(5,3*r.modalFrequencyHz(2)))]);
  yl=ylim;for k=1:2
   plot([r.modalFrequencyHz(k),r.modalFrequencyHz(k)],yl,'k:');
   text(r.modalFrequencyHz(k),yl(2)*(.76-.14*(k-1)),sprintf('f%d=%.3f Hz',k,r.modalFrequencyHz(k)),'FontSize',9);
  end
  lh=legend('Experiment','Nonlinear theory','Small-angle theory');set(lh,'Visible','on');
  plotTitle(label,sprintf('Link %d | blue: observed; red: nonlinear; purple: linear | measured bin %.4g Hz; bins %.4g Hz',j,r.experimentalPeakHz(j),r.fftBinSpacingHz));
 end;savePlots(f,out,'03_spectra_theory_overlay');
end
f=figure('Name','Energy with the entered model parameters','Color','w');hold on;
plot(t,r.energyExperimentalModelJ,'Color',colors(1,:));plot(t,r.energyNonlinearJ,'Color',colors(2,:));grid on;
xlabel('Time since selected start (s)');ylabel('Model-based mechanical energy (J)');lh=legend('Experiment-derived','Nonlinear ideal model');set(lh,'Visible','on');plotTitle(label,'Blue: experiment-derived model energy | red: ideal nonlinear prediction');savePlots(f,out,'04_energy_model_check');
end
function v=wrappedPlot(v)
v=atan2(sin(v),cos(v));jump=[false;abs(diff(v))>pi];v(jump)=NaN;
end
function [a,b]=runs(mask)
z=diff([false;mask(:);false]);a=find(z==1);b=find(z==-1)-1;
end
function writeCSV(path,data,header)
fid=fopen(path,'w');assert(fid>=0,'Cannot open output CSV.');fprintf(fid,'%s\n',header);
fprintf(fid,[repmat('%.12g,',1,size(data,2)-1),'%.12g\n'],data');fclose(fid);
end
function savePlots(f,out,name)
saveas(f,fullfile(out,[name '.png']));savefig(f,fullfile(out,[name '.fig']));
end
function plotTitle(label,key)
h=title(label,'Interpreter','none','FontSize',11);set(h,'Units','normalized','Position',[.5,1.12,0]);
text(0,1.035,key,'Units','normalized','FontSize',9,'Interpreter','none','Clipping','off');
end
