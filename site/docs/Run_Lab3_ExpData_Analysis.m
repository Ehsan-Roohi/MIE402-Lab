function result = Run_Lab3_ExpData_Analysis(inputFile, outputFolder)
% Main entry point. Click Run with no inputs, or supply a MAT path for batch use.
% Example: R = Run_Lab3_ExpData_Analysis('recording.mat','results_folder');
% Lab 3 tracking-aware analysis, 20 October 2026.
% STUDENTS: open this file in MATLAB, click Run, and select your ExpData MAT.
% No sineFit, Python, or additional helper downloads are needed for this script.
% Results are saved beside the input file in a new *_Lab3_results folder.
% Keep the original recording and inspect tracking flags before using the figures.
% ExpData: time_s,x1_mm,y1_mm,x2_mm,y2_mm. Fixed pivot; x right, y up.
% MATLAB port of the Python algorithm tested on the supplied recordings.
% Runtime validation is documented in MIE402_Lab3_MATLAB_README.txt.
result = struct();
fprintf('MIE402 Lab 3: processed link-length output.\nFile: %s\n',mfilename('fullpath'));
lengthTolerance = 0.20;       % QC screen; not a physical calibration uncertainty
maxGapSeconds = 0.05;        % full anchor-to-anchor interval, not missing-row count
maxBridgeDegrees = 60;       % do not infer large turns through a missing interval
velocityWindowSeconds = .021;
measuredLengthsMM = [];      % optional [L1,L2] measured lengths; empty uses robust medians
if nargin < 1 || isempty(inputFile)
    [filename,folder] = uigetfile('*.mat','Select Lab 3 ExpData');
    if isequal(filename,0), return; end
    inputFile=fullfile(folder,filename);
else
    [folder,base,ext]=fileparts(inputFile); filename=[base,ext];
    if isempty(folder),folder=pwd;end
end
S=load(inputFile);
assert(isfield(S,'ExpData'),'The MAT file has no ExpData.');
D=double(S.ExpData);
assert(size(D,2)>=5 && size(D,1)>=20,'Need >=20 rows and t,x1,y1,x2,y2.');
D=D(:,1:5); t=D(:,1); xyz=D(:,2:5); N=numel(t);
assert(all(isfinite(t)) && all(diff(t)>0),'Time must be finite and strictly increasing.');
[~,base]=fileparts(filename);
if nargin < 2 || isempty(outputFolder)
    out=fullfile(folder,[base,'_Lab3_results']);
else
    out=outputFolder;
end
if ~exist(out,'dir'), mkdir(out); end

dt=median(diff(t));
v1=xyz(:,1:2); v2=xyz(:,3:4)-xyz(:,1:2);
L=[hypot(v1(:,1),v1(:,2)),hypot(v2(:,1),v2(:,2))];
% A whole missing joint cannot be reconstructed from neighboring samples.
availableVectors=isfinite(L) & L>0;
if any(sum(availableVectors,1)<20)
    result=analyzeAvailablePositions(D,out,maxGapSeconds);
    return;
end
refs=zeros(1,2);
for j=1:2
    q=L(isfinite(L(:,j)) & L(:,j)>0,j);
    assert(numel(q)>=20,'Not enough nonzero link vectors to establish geometry.');
    refs(j)=median(q);
end
if ~isempty(measuredLengthsMM)
    assert(numel(measuredLengthsMM)==2 && all(isfinite(measuredLengthsMM)) && all(measuredLengthsMM>0), ...
        'Measured lengths must be two positive values in mm.');
    refs=measuredLengthsMM(:)';
end
finite1=all(isfinite(v1),2); finite2=all(isfinite(xyz),2);
zeroLength=isfinite(L) & L<=max(1e-9,1e-6*refs);
geometry=abs(L./refs-1)<=lengthTolerance & ~zeroLength;
observed=[finite1 & geometry(:,1),finite2 & geometry(:,1) & geometry(:,2)];
rawAngles=[atan2(v1(:,1),-v1(:,2)),atan2(v2(:,1),-v2(:,2))];
principal=nan(N,2); continuous=principal; omega=principal;
filled=false(N,2); derivativeInfluence=filled;
for j=1:2
    [principal(:,j),continuous(:,j),filled(:,j)]=repairAngle(t,rawAngles(:,j),observed(:,j),maxGapSeconds,maxBridgeDegrees);
    [omega(:,j),derivativeInfluence(:,j)]=localVelocity(t,continuous(:,j),filled(:,j),velocityWindowSeconds);
    fprintf('Link %d: reference %.3f mm; observed %d; short-gap estimates %d; unresolved %d.\n', ...
        j,refs(j),nnz(observed(:,j)),nnz(filled(:,j)),nnz(~isfinite(continuous(:,j))));
end
% Export explicitly flagged coordinate estimates as well as angular estimates.
% Original D/xyz are never changed. A single x=0 or y=0 is a valid coordinate.
repairedCoordinates=xyz;
repairedCoordinates(~observed(:,1),1:2)=NaN;
repairedCoordinates(~observed(:,2),3:4)=NaN;
q=filled(:,1);
repairedCoordinates(q,1)=refs(1)*sin(principal(q,1));
repairedCoordinates(q,2)=-refs(1)*cos(principal(q,1));
q=filled(:,2) & all(isfinite(repairedCoordinates(:,1:2)),2);
repairedCoordinates(q,3)=repairedCoordinates(q,1)+refs(2)*sin(principal(q,2));
repairedCoordinates(q,4)=repairedCoordinates(q,2)-refs(2)*cos(principal(q,2));
% L is the processed length used in standard outputs. Keep the original
% tracking diagnostic separately as L_raw; NEVER overwrite the input D.
L_raw=L;
L_processed=[hypot(repairedCoordinates(:,1),repairedCoordinates(:,2)), ...
    hypot(repairedCoordinates(:,3)-repairedCoordinates(:,1), ...
          repairedCoordinates(:,4)-repairedCoordinates(:,2))];
L_processed(~isfinite(L_processed) | L_processed<=max(1e-9,1e-6*refs))=NaN;
L=L_processed;
writeNumericCSV(fullfile(out,'link_lengths_with_quality_flags.csv'), ...
    [t,L_raw,L_processed,observed,filled,zeroLength], ...
    {'time_s','L1_raw_mm','L2_raw_mm','L1_processed_mm','L2_processed_mm', ...
    'link1_observed','link2_observed','link1_estimated','link2_estimated', ...
    'link1_zero_length_raw','link2_zero_length_raw'});
writeNumericCSV(fullfile(out,'coordinates_with_quality_flags.csv'), ...
    [D,repairedCoordinates,zeroLength,filled], ...
    {'time_s','x1_raw_mm','y1_raw_mm','x2_raw_mm','y2_raw_mm', ...
    'x1_repaired_mm','y1_repaired_mm','x2_repaired_mm','y2_repaired_mm', ...
    'link1_zero_length','link2_zero_length','link1_estimated','link2_estimated'});
fprintf('Timestamps imply %.3f samples/s. Verify original CAPTURE fps, not playback fps.\n',1/dt);
disp('Length references are QC estimates, not independent calibration. Raw coordinates are preserved.');
disp('Principal angles wrap at +/-180 deg; continuous angles can legitimately exceed 360 deg.');
disp('Continuous-angle turn counts are not linked across unresolved gaps.');

csvData=[D,rad2deg(principal),rad2deg(continuous),omega,L_raw,L_processed,observed,filled,derivativeInfluence];
headers={'time_s','x1_raw_mm','y1_raw_mm','x2_raw_mm','y2_raw_mm', ...
 'theta1_principal_deg','theta2_principal_deg','theta1_continuous_deg','theta2_continuous_deg', ...
 'omega1_rad_s','omega2_rad_s','L1_raw_mm','L2_raw_mm', ...
 'L1_processed_mm','L2_processed_mm','link1_observed','link2_observed', ...
 'link1_interpolated','link2_interpolated','omega1_influenced','omega2_influenced'};
writeNumericCSV(fullfile(out,'analysis_with_quality_flags.csv'),csvData,headers);
save(fullfile(out,'Lab3_Analysis.mat'),'D','t','L','L_raw','L_processed','refs','principal','continuous','omega', ...
 'observed','filled','derivativeInfluence','lengthTolerance','maxGapSeconds','maxBridgeDegrees','velocityWindowSeconds','-v7');

colors=lines(2);
f=figure('Name','Lab 3: orientation and angular velocity');
subplot(2,1,1);hold on
for j=1:2
    a=rad2deg(principal(:,j)); a([false;abs(diff(a))>180])=NaN;
    plot(t,a,'Color',colors(j,:),'DisplayName',sprintf('Link %d',j));
    q=filled(:,j);plot(t(q),rad2deg(principal(q,j)),'o','Color',colors(j,:), ...
        'MarkerSize',3,'DisplayName',sprintf('Link %d short-gap estimates',j));
end
grid on;hLegend=legend('show');set(hLegend,'Visible','on');ylabel('Principal angle (deg)');
title('Angles: blue = link 1; orange = link 2; circles = short-gap estimates'); xlim([t(1),t(end)]);
subplot(2,1,2);plot(t,omega);grid on;hLegend=legend('Link 1','Link 2');set(hLegend,'Visible','on');
xlabel('Original MAT time (s)');ylabel('Angular velocity (rad/s)');
title('Angular velocity: blue = link 1; orange = link 2'); xlim([t(1),t(end)]);
saveas(f,fullfile(out,'02_angles_and_velocity.png'));
savefig(f,fullfile(out,'02_angles_and_velocity.fig'));

f=figure('Name','Lab 3: continuous rotation');
plot(t,rad2deg(continuous));grid on;hLegend=legend('Link 1','Link 2');set(hLegend,'Visible','on');
xlabel('Original MAT time (s)');ylabel('Continuous angle (deg)');
title('Continuous rotation: blue = link 1; orange = link 2'); xlim([t(1),t(end)]);
saveas(f,fullfile(out,'04_continuous_rotation.png'));
savefig(f,fullfile(out,'04_continuous_rotation.fig'));

f=figure('Name','Lab 3: processed link lengths','NumberTitle','off'); hold on;
for j=1:2
    plot(t,L_processed(:,j),'Color',colors(j,:),'LineWidth',1.1);
    q=filled(:,j) & isfinite(L_processed(:,j));
    plot(t(q),L_processed(q,j),'o','Color',colors(j,:),'MarkerSize',4);
    plot([t(1),t(end)],[refs(j),refs(j)],'--','Color',colors(j,:));
end
grid on;xlabel('Original MAT time (s)');ylabel('Processed link length (mm)');
title('Processed lengths: blue = link 1; orange = link 2; circles = estimates');
xlim([t(1),t(end)]);
% No raw zero detections are joined into the processed length curves.
saveas(f,fullfile(out,'01_tracking_geometry.png'));
savefig(f,fullfile(out,'01_tracking_geometry.fig'));

% Both spectra use the SAME longest joint-valid segment; never join across gaps.
fftInterval=[NaN,NaN]; fftPeaks=[NaN,NaN]; fftBinSpacing=NaN;
common=all(isfinite(continuous),2); [starts,stops]=validRuns(common);
f=figure('Name','Lab 3: spectra');
if isempty(starts)
    warning('No joint-valid segment; inspect/retrack the existing video.');
else
    [~,k]=max(stops-starts+1);a=starts(k);b=stops(k);idx=a:b;n=numel(idx);
    dti=median(diff(t(idx)));
    if n<32 || max(abs(diff(t(idx))-dti))>.02*dti
        warning('No sufficiently long uniform common segment for an FFT. Time-domain outputs remain available.');
    else
        fftInterval=[t(a),t(b)]; fftBinSpacing=1/(n*dti);
        freq=(0:floor(n/2))'/(n*dti); w=.5-.5*cos(2*pi*(0:n-1)'/(n-1));
        for j=1:2
            x=continuous(idx,j); unit='rad'; quantity='angle';
            if max(x)-min(x)>2*pi
                x=sin(x);unit='1';quantity='sin(theta), orientation component';
            end
            Z=fft((x-mean(x)).*w);amp=2*abs(Z(1:numel(freq)))/sum(w);
            amp(1)=amp(1)/2;if mod(n,2)==0,amp(end)=amp(end)/2;end
            [~,ip]=max(amp(2:end));ip=ip+1;
            fprintf('Link %d largest FFT bin %.4f Hz; common interval %.3f--%.3f s; bins %.4f Hz.\n', ...
                j,freq(ip),t(a),t(b),1/(n*dti));
            fftPeaks(j)=freq(ip);
            subplot(1,2,j);plot(freq,amp);hold on;plot([freq(ip),freq(ip)],[0,max(amp)],'--');grid on
            xlim([0,min(15,freq(end))]);xlabel('Frequency (Hz)');ylabel(['One-sided amplitude (',unit,')']);
            title(sprintf('Link %d: %.3f Hz; %s',j,freq(ip),quantity));
            writeNumericCSV(fullfile(out,sprintf('link%d_spectrum.csv',j)),[freq,amp],{'frequency_hz','amplitude'});
        end
    end
end
saveas(f,fullfile(out,'03_frequency_spectra.png'));
savefig(f,fullfile(out,'03_frequency_spectra.fig'));
disp(['Saved to ',out]);
disp('Large-angle spectra describe this record; they are not automatically the two small-angle modes.');
disp('Long gaps require review of the EXISTING video, not invented positions or a new experiment.');

result=struct('time',t,'raw',D,'lengths',L_processed,'rawLengths',L_raw,'referenceLengths',refs, ...
    'principal',principal,'continuous',continuous,'omega',omega,'observed',observed, ...
    'filled',filled,'derivativeInfluence',derivativeInfluence, ...
    'repairedCoordinates',repairedCoordinates,'zeroLength',zeroLength, ...
    'fftInterval',fftInterval,'fftPeaks',fftPeaks,'fftBinSpacing',fftBinSpacing,'outputFolder',out);
save(fullfile(out,'Lab3_Analysis.mat'),'result','-v7','-append');
end

function writeNumericCSV(path,data,headers)
fid=fopen(path,'w'); assert(fid>=0,'Cannot write CSV output.');
cleanup=onCleanup(@() fclose(fid));
for k=1:numel(headers)
    if k>1,fprintf(fid,',');end
    fprintf(fid,'%s',headers{k});
end
fprintf(fid,'\n');
fmt=[repmat('%.17g,',1,size(data,2)-1),'%.17g\n'];
fprintf(fid,fmt,data.');
end

function [a,u,filled]=repairAngle(t,a,observed,maxGap,maxDegrees)
a(~observed)=NaN;filled=false(size(a));n=numel(t);
[starts,stops]=validRuns(~observed);
for k=1:numel(starts)
    s=starts(k);e=stops(k);
    if s==1 || e==n,continue;end
    duration=t(e+1)-t(s-1);
    delta=atan2(sin(a(e+1)-a(s-1)),cos(a(e+1)-a(s-1)));
    if duration<=maxGap+10*eps(max(abs(t))) && abs(delta)<=deg2rad(maxDegrees)
        a(s:e)=a(s-1)+(t(s:e)-t(s-1))/duration*delta;filled(s:e)=true;
    end
end
u=nan(size(a));[starts,stops]=validRuns(isfinite(a));
for k=1:numel(starts),idx=starts(k):stops(k);u(idx)=unwrap(a(idx));end
a=atan2(sin(u),cos(u));
end

function [omega,influence]=localVelocity(t,theta,filled,windowSeconds)
omega=nan(size(theta));influence=false(size(theta));
[starts,stops]=validRuns(isfinite(theta));
for k=1:numel(starts)
    a=starts(k);b=stops(k);n=b-a+1;if n<5,continue;end
    dt=median(diff(t(a:b)));w=max(5,2*floor(round(windowSeconds/dt)/2)+1);
    w=min(w,n-mod(n+1,2));h=floor(w/2);
    influence(a:a+h-1)=true;influence(b-h+1:b)=true;
    local=conv(double(filled(a:b)),ones(w,1),'same')>0;
    influence(a:b)=influence(a:b)|local;
    for i=a+h:b-h
        if influence(i),continue;end
        idx=i-h:i+h;z=(t(idx)-t(i))/dt;
        beta=[ones(w,1),z,z.^2,z.^3]\theta(idx);
        omega(i)=beta(2)/dt;
    end
end
end

function [starts,stops]=validRuns(mask)
e=diff([false;logical(mask(:));false]);starts=find(e==1);stops=find(e==-1)-1;
end


function result=analyzeAvailablePositions(D,out,maxGapSeconds)
t=D(:,1); raw=D(:,2:5); repaired=raw;
observed=false(numel(t),2); filled=observed;
for j=1:2
    cols=2*j-1:2*j;
    xy=raw(:,cols);
    % Reject the zero VECTOR, not a zero component of a real position.
    good=all(isfinite(xy),2);
    if j==1,good=good & hypot(xy(:,1),xy(:,2))>1e-9;end
    if j==2
        both=all(isfinite(raw),2);
        duplicate=both & hypot(raw(:,3)-raw(:,1),raw(:,4)-raw(:,2))<=1e-9;
        good=good & ~duplicate;
    end
    observed(:,j)=good; xy(~good,:)=NaN;
    [starts,stops]=validRuns(~good);
    for k=1:numel(starts)
        a=starts(k);b=stops(k);
        if a==1 || b==numel(t),continue;end
        duration=t(b+1)-t(a-1);
        if duration<=maxGapSeconds+10*eps(max(abs(t)))
            alpha=(t(a:b)-t(a-1))/duration;
            xy(a:b,:)=xy(a-1,:)+(xy(b+1,:)-xy(a-1,:)).*alpha;
            filled(a:b,j)=true;
        end
    end
    repaired(:,cols)=xy;
    fprintf('Tracked point %d: observed %d; short-gap estimates %d; missing %d.\n', ...
        j,nnz(good),nnz(filled(:,j)),nnz(~all(isfinite(xy),2)));
end
status='incomplete_tracking';
writeNumericCSV(fullfile(out,'available_positions_with_quality_flags.csv'), ...
    [D,repaired,observed,filled], ...
    {'time_s','x1_raw_mm','y1_raw_mm','x2_raw_mm','y2_raw_mm', ...
    'x1_repaired_mm','y1_repaired_mm','x2_repaired_mm','y2_repaired_mm', ...
    'point1_observed','point2_observed','point1_estimated','point2_estimated'});
% With no first joint, lower-link angle/length and the full pendulum FFT
% are not identifiable. Store NaNs rather than inventing an angle or a joint.
angles=nan(numel(t),2);
result=struct('status',status,'time',t,'raw',D,'repairedCoordinates',repaired, ...
    'observed',observed,'filled',filled,'principal',angles,'continuous',angles, ...
    'omega',angles,'outputFolder',out);
save(fullfile(out,'Lab3_Available_Positions.mat'),'result','-v7');
fid=fopen(fullfile(out,'READ_AVAILABLE_POSITIONS.txt'),'w');
assert(fid>=0,'Cannot write analysis notes.');
fprintf(fid,'INCOMPLETE DOUBLE-PENDULUM TRACKING\n');
fprintf(fid,'At least one link lacks enough observed vectors. Full link angles, angular velocities and modal spectra are not computed.\n');
fprintf(fid,'A missing joint for the whole record has no valid neighbors and cannot be interpolated. Review/retrack the ORIGINAL video in Double Pendulum mode with both centers selected.\n');
fprintf(fid,'The saved x/y curves describe stored tracked POINT positions relative to the fixed pivot; they are not lower-link angles.\n');
fprintf(fid,'Only short internal gaps bounded by valid coordinates are interpolated (anchor interval <= %.3f s). Estimates are flagged; endpoints and longer gaps remain missing.\n',maxGapSeconds);
for j=1:2
    fprintf(fid,'Point %d: observed %d, estimates %d, unresolved %d of %d rows.\n', ...
        j,nnz(observed(:,j)),nnz(filled(:,j)),nnz(~all(isfinite(repaired(:,2*j-1:2*j)),2)),numel(t));
end
fclose(fid);
present=find(any(observed,1));colors=lines(2);
if ~isempty(present)
    f=figure('Name','Available tracked positions');
    for component=1:2
        subplot(2,1,component);hold on;
        for j=present
            col=2*j-2+component;
            plot(t,repaired(:,col),'Color',colors(j,:));
            q=filled(:,j);plot(t(q),repaired(q,col),'o','Color',colors(j,:),'MarkerSize',4);
        end
        grid on;xlim([t(1),t(end)]);
        if component==1,ylabel('Horizontal position x (mm)');else,ylabel('Vertical position y (mm)');end
        title('Stored point positions: blue = point 1; orange = point 2; circles = estimates');
    end
    xlabel('Original MAT time (s)');
    saveas(f,fullfile(out,'01_available_positions.png'));
    savefig(f,fullfile(out,'01_available_positions.fig'));
    f=figure('Name','Available tracked paths');hold on;
    for j=present
        plot(repaired(:,2*j-1),repaired(:,2*j),'Color',colors(j,:));
    end
    grid on;axis equal;xlabel('Horizontal position x (mm)');ylabel('Vertical position y (mm)');
    title('Stored point paths: blue = point 1; orange = point 2');
    saveas(f,fullfile(out,'02_available_paths.png'));
    savefig(f,fullfile(out,'02_available_paths.fig'));
end
warning('Incomplete double-pendulum tracking: see READ_AVAILABLE_POSITIONS.txt. Missing entire joints are NOT reconstructed.');
disp(['Available-position results saved to ',out]);
end
