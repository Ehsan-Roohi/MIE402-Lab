% Synthetic verification only: these are NOT student experimental records.
addpath('site/docs');
rand('seed',42);randn('seed',42);
out=fullfile(tempdir(),'lab4_spring_checks');if ~exist(out,'dir'),mkdir(out);end
c=struct('mode','manual','label','A','massValue',200,'massUnit','g','B',7.3,'frequencyUnit','rad/s','alpha',0);
r=Lab4_Spring_Stiffness_Analysis(c);assert(abs(r.k_N_m-10.658)<1e-10);
c.massValue=.2;c.massUnit='kg';c.B=7.3/(2*pi);c.frequencyUnit='Hz';r=Lab4_Spring_Stiffness_Analysis(c);assert(abs(r.k_N_m-10.658)<1e-10);
c.massValue=1.962;c.massUnit='N';c.B=7.3;c.frequencyUnit='rad/s';r=Lab4_Spring_Stiffness_Analysis(c);assert(abs(r.mass_kg-.2)<1e-12);
c.B=0;failed=false;try,Lab4_Spring_Stiffness_Analysis(c);catch,failed=true;end;assert(failed);
t=(0:.04:10)';b=7.3;a=.11;
y=1.962+.35*exp(-a*t).*cos(b*t+.6)+.002*randn(size(t));
c=struct('mode','data','label','Synthetic_damped','massValue',200,'massUnit','g','time',t,'force',y,'damped',true,'outputDir',out,'makePlots',true);
r=Lab4_Spring_Stiffness_Analysis(c);
assert(abs(r.B_rad_s-b)/b<.005);assert(abs(r.alpha_s_inv-a)<.01);
assert(abs(r.k_N_m-.2*(b*b+a*a))/.2/(b*b+a*a)<.01);
assert(r.R2>.995);assert(exist(fullfile(out,'Synthetic_damped_Force_Fit.png'),'file')==2);
fprintf('Damped test: B=%.6f alpha=%.6f k=%.6f R2=%.6f\n',r.B_rad_s,r.alpha_s_inv,r.k_N_m,r.R2);
% Standard Vernier-like CSV: metadata, headers, units, then numeric rows.
f=fullfile(out,'synthetic_force_export.csv');fid=fopen(f,'w');
fprintf(fid,'Vernier Graphical Analysis\nSynthetic verification record\nTime,Force\ns,N\n');
fprintf(fid,'%.9f,%.9f\n',[t,y]');fclose(fid);
c=rmfield(c,{'time','force'});c.mode='file';c.file=f;c.timeColumn=1;c.forceColumn=2;c.label='Synthetic_CSV';c.startTime=.4;c.endTime=9.6;
r=Lab4_Spring_Stiffness_Analysis(c);assert(abs(r.B_rad_s-b)<.04);assert(abs(r.k_N_m-10.66042)<.10);
% No decay, negative force sign, substantial offset: ordinary sine route.
c=struct('mode','data','label','Synthetic_sine','massValue',.2,'massUnit','kg','time',t,'force',-4-.25*sin(9.1*t+.8),'damped',false);
r=Lab4_Spring_Stiffness_Analysis(c);assert(abs(r.B_rad_s-9.1)<1e-4);assert(abs(r.k_N_m-16.562)<.001);
% Ensure multiple true frequencies are not silently approved as a clean sine.
c.force=sin(7*t)+sin(11*t);c.damped=true;failed=false;
try,Lab4_Spring_Stiffness_Analysis(c);catch,failed=true;end;assert(failed);
% Flat/missing/bad time inputs fail without fabricated stiffness.
c.force=ones(size(t));failed=false;try,Lab4_Spring_Stiffness_Analysis(c);catch,failed=true;end;assert(failed);
c.force=y;c.time=t;c.time(5)=c.time(4);failed=false;try,Lab4_Spring_Stiffness_Analysis(c);catch,failed=true;end;assert(failed);
c.time=t;c.time(101:end)=c.time(101:end)+.2;failed=false;try,Lab4_Spring_Stiffness_Analysis(c);catch,failed=true;end;assert(failed);
fprintf('ALL SPRING STIFFNESS CHECKS PASSED. Synthetic test artifacts: %s\n',out);
