function R = Lab5_Analyze_Record(t,x,P,mode,fHz)
% Toolbox-free analysis of one selected record, all quantities in SI.
% P.m [kg], P.kFixed/P.kDrive [N/m], P.c [N*s/m] (harmonic), P.Y [m].
% fHz is measured motor rpm/60, not a guessed natural frequency.
t=t(:); x=x(:); t=t-t(1);
if numel(t)<30||numel(x)~=numel(t)||any(~isfinite([t;x]))||any(diff(t)<=0)
    error('Lab5:Data','At least 30 finite paired samples with increasing time are required.');
end
if any(~isfinite([P.m,P.kFixed,P.kDrive]))||any([P.m,P.kFixed,P.kDrive]<=0)
    error('Lab5:Parameters','Mass and both spring stiffnesses must be positive SI values.');
end
dt=median(diff(t)); fs=1/dt;
if max(abs(diff(t)-dt))>0.05*dt, error('Lab5:Sampling','Uniform time spacing is required.'); end
wn=sqrt((P.kFixed+P.kDrive)/P.m);
R=struct('t',t,'x',x,'fs_Hz',fs,'fn_theory_Hz',wn/(2*pi));
if strcmpi(mode,'harmonic')
    if nargin<5||~isscalar(fHz)||~isfinite(fHz)||fHz<=0||fHz>=fs/2
        error('Lab5:Frequency','Measured drive frequency must be positive and below Nyquist.');
    end
    if fHz>fs/10, warning('Lab5:Resolution','Fewer than 10 samples per forcing cycle. Interpret cautiously.'); end
    if ~isfinite(P.c)||P.c<=0||~isfinite(P.Y)||P.Y<=0
        error('Lab5:Parameters','Enter measured positive damping c and input PEAK amplitude Y.');
    end
    if t(end)*fHz<5, error('Lab5:Window','Select at least five steady-state cycles.'); end
    w=2*pi*fHz; A=[ones(size(t)), t-mean(t), cos(w*t),sin(w*t)]; b=A\x;
    fit=A*b; X=hypot(b(3),b(4)); H=P.kDrive/complex(P.kFixed+P.kDrive-P.m*w^2,P.c*w);
    half=t<=median(t); a1=localAmplitude(t(half),x(half),w); a2=localAmplitude(t(~half),x(~half),w);
    change=abs(a2-a1)/max((a1+a2)/2,eps);
    if change>0.10, warning('Lab5:SteadyState','First/second half amplitudes differ >10%%; choose a later window or inspect the run.'); end
    R.fit=fit; R.X_m=X; R.Y_m=P.Y; R.gain=X/P.Y; R.gain_dB=20*log10(max(R.gain,realmin));
    R.drive_Hz=fHz; R.gain_theory=abs(H); R.half_amplitude_change=change;
    R.rmse_m=sqrt(mean((x-fit).^2)); R.offset_m=b(1); R.drift_m_per_s=b(2);
    R.phase_note='Output fit phase is relative to CSV start; input/output phase requires a synchronized input record.';
elseif strcmpi(mode,'impulse')
    if t(end)*wn/(2*pi)<3, error('Lab5:Window','Select at least three complete decay cycles after contact ends.'); end
    % Variable projection: offset, cosine and sine coefficients solved exactly.
    % Search several frequencies to avoid a poor initial local minimum.
    best=Inf; bestp=[];
    for ratio=[0.6 0.85 1 1.2 1.5]
        p0=log([0.04*wn,ratio*wn]);
        [p,val]=fminsearch(@(p) decayCost(p,t,x),p0,optimset('Display','off','MaxIter',1600,'MaxFunEvals',3500,'TolX',1e-9));
        if val<best, best=val; bestp=p; end
    end
    alpha=exp(bestp(1)); wd=exp(bestp(2));
    if wd>=pi*fs||wd*t(end)<6*pi||alpha>wd
        error('Lab5:Fit','Decay fit is not a resolved underdamped oscillation; check the data and interval.');
    end
    A=[ones(size(t)),exp(-alpha*t).*cos(wd*t),exp(-alpha*t).*sin(wd*t)]; b=A\x;
    R.fit=A*b; R.c_est_Ns_m=2*P.m*alpha; R.fd_fit_Hz=wd/(2*pi);
    R.fn_fit_Hz=sqrt(wd^2+alpha^2)/(2*pi); R.zeta_fit=alpha/sqrt(wd^2+alpha^2);
    R.rmse_m=sqrt(mean((x-R.fit).^2)); R.alpha_per_s=alpha;
    % Theory uses measured m and k, identified c, and fitted initial state.
    if alpha<wn
        wt=sqrt(wn^2-alpha^2); At=[exp(-alpha*t).*cos(wt*t),exp(-alpha*t).*sin(wt*t)];
        bt=At\(x-b(1)); R.theory=b(1)+At*bt;
    else, R.theory=nan(size(x)); end
    if R.rmse_m>0.15*max(std(x),eps)
        warning('Lab5:FitQuality','Large decay-fit residual; inspect friction, impacts, slack springs and fit window.');
    end
else, error('Lab5:Mode','Mode must be impulse or harmonic.'); end
% Hann-window spectrum, coherent-gain corrected, one-sided peak amplitudes.
N=numel(t); win=0.5-0.5*cos(2*pi*(0:N-1)'/N); xx=x-mean(x);
z=fft(xx.*win); n=floor(N/2)+1; spec=abs(z(1:n))/sum(win);
if rem(N,2)==0, spec(2:end-1)=2*spec(2:end-1); else, spec(2:end)=2*spec(2:end); end
R.f_Hz=(0:n-1)'*fs/N; R.spectrum_m=spec; R.bin_Hz=fs/N;
end
function X=localAmplitude(t,x,w)
A=[ones(size(t)),t-mean(t),cos(w*t),sin(w*t)]; b=A\x; X=hypot(b(3),b(4));
end
function value=decayCost(p,t,x)
a=exp(p(1)); w=exp(p(2));
if ~isfinite(a+w)||a>100||w>pi/median(diff(t))||w<2*pi/t(end), value=1e10; return; end
A=[ones(size(t)),exp(-a*t).*cos(w*t),exp(-a*t).*sin(w*t)]; b=A\x;
value=sum((x-A*b).^2);
end
