function Tracking = Run_Lab3_Ring_Video_Tracker(videoFile, cfg)
% Track two ring-shaped bobs directly in an existing pendulum video.
% Requires MATLAB + Image Processing Toolbox, or GNU Octave + image/video.
% This is a separate tracker,
% not a modification of the installed Pendulum Motion Analyzer application.
% Run without inputs to select a video and initialize by clicking.
% No interpolation: unaccepted frames remain NaN in every output.
if nargin<1 || isempty(videoFile)
    [f,p]=uigetfile({'*.mp4;*.avi;*.mov','Video files'});
    if isequal(f,0), Tracking=[]; return; end
    videoFile=fullfile(p,f);
end
if nargin<2, cfg=struct; end
assert(exist('imfill','file')==2,'Image Processing Toolbox is required.');
v=VideoReader(videoFile);
if ~isfield(cfg,'pivotPx') || ~isfield(cfg,'initialCentersPx') || ~isfield(cfg,'innerRadiiPx')
    first=readFrame(v);
    h=figure('Name','Initialize ring tracker','NumberTitle','off'); imshow(first);
    title('Click the FIXED PIVOT center'); [x,y]=ginput(1); cfg.pivotPx=[x,y];
    title('Click the center of the UPPER moving joint (bob 1)'); [x,y]=ginput(1); cfg.initialCentersPx(1,:)=[x,y];
    title('Click the center of the LOWER moving bob (bob 2)'); [x,y]=ginput(1); cfg.initialCentersPx(2,:)=[x,y];
    title('Click the INNER EDGE of the dark hole in bob 1'); [x,y]=ginput(1); cfg.innerRadiiPx(1)=norm([x,y]-cfg.initialCentersPx(1,:));
    title('Click the INNER EDGE of the dark hole in bob 2'); [x,y]=ginput(1); cfg.innerRadiiPx(2)=norm([x,y]-cfg.initialCentersPx(2,:));
    close(h);
end
if ~isfield(cfg,'captureFps')
    a=inputdlg({'Actual CAMERA CAPTURE fps (NOT slow-motion playback fps). Blank = frame-indexed output only:',...
        'Measured upper pivot-to-joint length in mm. Blank = pixel output only:'},'Timing and scale',[1,85],{'',''});
    if isempty(a), Tracking=[];return;end
    cfg.captureFps=str2double(a{1});cfg.upperLengthMm=str2double(a{2});
end
if ~isfield(cfg,'upperLengthMm'),cfg.upperLengthMm=NaN;end
if ~isfield(cfg,'maxFrames'),cfg.maxFrames=Inf;end
if ~isfield(cfg,'makeFigures'),cfg.makeFigures=true;end
if ~isfield(cfg,'detectionScale'),cfg.detectionScale=.5;end
if ~isfield(cfg,'startFrame'),cfg.startFrame=0;end
assert(isscalar(cfg.detectionScale) && cfg.detectionScale>0 && cfg.detectionScale<=1,'detectionScale must be in (0,1].');
if ~isfield(cfg,'outputFolder'),[p,n]=fileparts(videoFile);cfg.outputFolder=fullfile(p,[n '_RingTracking']);end
if ~exist(cfg.outputFolder,'dir'),mkdir(cfg.outputFolder);end
cfg.pivotPx=reshape(cfg.pivotPx,1,2);cfg.innerRadiiPx=reshape(cfg.innerRadiiPx,1,2);
assert(all(isfinite([cfg.pivotPx,cfg.initialCentersPx(:)',cfg.innerRadiiPx])) && all(cfg.innerRadiiPx>0),'Invalid initialization.');
ref=[norm(cfg.initialCentersPx(1,:)-cfg.pivotPx),norm(diff(cfg.initialCentersPx,1,1))];
assert(all(ref>0),'The pivot and two bob centers must be distinct.');
if ~isfield(cfg,'searchRadiusPx'),cfg.searchRadiusPx=max(3*max(cfg.innerRadiiPx),.25*min(ref));end
% Reopen rather than assigning CurrentTime: Octave's video package does not
% implement seeking via that property. The first decoded frame stays frame 0.
clear v;v=VideoReader(videoFile);
assert(isscalar(cfg.startFrame) && isfinite(cfg.startFrame) && cfg.startFrame>=0 && cfg.startFrame==floor(cfg.startFrame),'startFrame must be a zero-based integer.');
for skip=1:cfg.startFrame
    assert(hasFrame(v),'startFrame is beyond the video.');readFrame(v);
end
last=cfg.initialCentersPx;centers=nan(max(1,min(cfg.maxFrames,ceil(v.Duration*v.FrameRate)+2)),4);accepted=false(size(centers,1),1);k=0;
while hasFrame(v) && k<cfg.maxFrames
    frame=readFrame(v);if isempty(frame),break;end;k=k+1;
    for scanMode=1:2
    if scanMode==1
        cand=ringCandidates(frame,cfg.innerRadiiPx,cfg.detectionScale,last,cfg.searchRadiusPx);
    else
        cand=ringCandidates(frame,cfg.innerRadiiPx,cfg.detectionScale,[],Inf);
    end
    scores=[];pairs=[];
    for a=1:size(cand,1)
        for b=1:size(cand,1)
            if a==b,continue;end
            pair=cand([a,b],1:2);
            lens=[norm(pair(1,:)-cfg.pivotPx),norm(diff(pair,1,1))];
            le=abs(lens./ref-1);re=abs(cand([a,b],3)'./cfg.innerRadiiPx-1);
            if any(le>.10) || any(re>.25),continue;end
            % Geometry and ring size are primary; continuity resolves ties.
            score=sum((le/.04).^2)+sum((re/.15).^2)+sum((pair(:)-last(:)).^2)/10000;
            scores(end+1,1)=score;pairs(end+1,:)=[pair(1,:),pair(2,:)]; %#ok<AGROW>
        end
    end
    if ~isempty(scores)
        [s,order]=sort(scores);
        if numel(s)==1 || s(2)-s(1)>1
            centers(k,:)=pairs(order(1),:);accepted(k)=true;
            last=[centers(k,1:2);centers(k,3:4)];
            break;
        end
    end
    end
    if mod(k,1000)==0,fprintf('Processed %d frames; accepted %d pairs.\n',k,nnz(accepted(1:k)));end
end
assert(k>0,'No video frames could be decoded.');
centers=centers(1:k,:);accepted=accepted(1:k);frameIndex=cfg.startFrame+(0:k-1)';
vec1=centers(:,1:2)-cfg.pivotPx;vec2=centers(:,3:4)-centers(:,1:2);
lengths=[hypot(vec1(:,1),vec1(:,2)),hypot(vec2(:,1),vec2(:,2))];
angles=[atan2(vec1(:,1),vec1(:,2)),atan2(vec2(:,1),vec2(:,2))];
% A video may contain an edit, buffer wrap, or sudden tracking jump. Retain
% raw detections but exclude flagged transitions from downstream dynamics.
step=max(hypot(diff(centers(:,1)),diff(centers(:,2))),hypot(diff(centers(:,3)),diff(centers(:,4))));
if ~isfield(cfg,'maxStepPx'),cfg.maxStepPx=.25*min(ref);end
continuityBreak=[false;step>cfg.maxStepPx];usable=accepted & ~continuityBreak;
Tracking=struct('frameZeroBased',frameIndex,'centersPx',centers,'pivotPx',cfg.pivotPx,...
    'lengthsPx',lengths,'thetaWrappedRad',angles,'acceptedPair',accepted,'configuration',cfg,...
    'encodedPlaybackFps',v.FrameRate,'sourceVideo',videoFile,'interpolatedPoints',0,...
    'continuityBreak',continuityBreak,'usableForContinuousAnalysis',usable);
save(fullfile(cfg.outputFolder,'TrackingPixels.mat'),'Tracking','-v7');
csvData=[frameIndex,centers,lengths,angles*180/pi,double(accepted),double(usable)];
fid=fopen(fullfile(cfg.outputFolder,'tracking_pixels.csv'),'w');
assert(fid>=0,'Cannot write tracking CSV.');
fprintf(fid,'FrameZeroBased,Bob1xPx,Bob1yPx,Bob2xPx,Bob2yPx,L1Px,L2Px,Theta1WrappedDeg,Theta2WrappedDeg,AcceptedPair,UsableForContinuousAnalysis\n');
fmt=[repmat('%.12g,',1,size(csvData,2)-1),'%.12g\n'];fprintf(fid,fmt,csvData');fclose(fid);
% Export the existing five-column ExpData convention only with supplied
% physical timing AND scale. Preserve y-up coordinates about the fixed pivot.
if isscalar(cfg.captureFps) && isfinite(cfg.captureFps) && cfg.captureFps>0 && ...
        isscalar(cfg.upperLengthMm) && isfinite(cfg.upperLengthMm) && cfg.upperLengthMm>0
    mmPerPx=cfg.upperLengthMm/ref(1);time=frameIndex/cfg.captureFps;
    absolute1=centers(:,1:2)-cfg.pivotPx;absolute2=centers(:,3:4)-cfg.pivotPx;
    ExpData=[time,mmPerPx*absolute1(:,1),-mmPerPx*absolute1(:,2),mmPerPx*absolute2(:,1),-mmPerPx*absolute2(:,2)]; %#ok<NASGU>
    ExpData(~usable,2:5)=NaN;
    save(fullfile(cfg.outputFolder,'RingTracking_ExpData.mat'),'ExpData','Tracking','-v7');
else
    fprintf('Physical ExpData NOT exported: supply verified captureFps and measured upperLengthMm.\n');
end
if cfg.makeFigures
f=figure('Name','Ring tracking quality');
lengths(~usable,:)=NaN;angles(~usable,:)=NaN;
subplot(2,1,1);plot(frameIndex,lengths);ylabel('Measured length (pixels)');legend('Link 1','Link 2');grid on;
title('Direct video tracking: unresolved frames remain blank');
subplot(2,1,2);plot(frameIndex,angles*180/pi);ylabel('Wrapped angle (degrees)');xlabel('Original frame number (zero based)');legend('Angle 1','Angle 2');grid on;
saveas(f,fullfile(cfg.outputFolder,'tracking_check.png'));savefig(f,fullfile(cfg.outputFolder,'tracking_check.fig'));
end
fprintf('Decoded %d frames. Accepted %d pairs; unresolved %d. No gap interpolation.\n',k,nnz(accepted),nnz(~accepted));
end

function candidates=ringCandidates(frame,radii,scale,previous,searchRadius)
candidates=zeros(0,3);
if isempty(previous)
    rois=[1,1,size(frame,2),size(frame,1)];
else
    rois=zeros(2,4);
    for q=1:2
        rois(q,:)=[max(1,floor(previous(q,1)-searchRadius)),max(1,floor(previous(q,2)-searchRadius)),...
            min(size(frame,2),ceil(previous(q,1)+searchRadius)),min(size(frame,1),ceil(previous(q,2)+searchRadius))];
    end
end
for roi=1:size(rois,1)
box=rois(roi,:);patch=frame(box(2):box(4),box(1):box(3),:);
if scale~=1,patch=imresize(patch,scale);end
if size(patch,3)==3,g=rgb2gray(patch);else,g=patch;end
g=im2double(g);
% Detect enclosed dark HOLES; the bright surrounding ring may join a rod.
% These thresholds suit bright rings on a dark background, not all targets.
for threshold=[85,105,125]/255
    bright=g>threshold;holes=imfill(bright,'holes') & ~bright;
    stats=regionprops(holes,'Area','Perimeter','Centroid');
    for j=1:numel(stats)
        s=stats(j);r=sqrt(s.Area/pi)/scale;
        if s.Perimeter<=0 || 4*pi*s.Area/s.Perimeter^2<.65 || r<.65*min(radii) || r>1.35*max(radii),continue;end
        xy=(s.Centroid-.5)/scale+.5+[box(1)-1,box(2)-1];
        if isempty(candidates) || all(hypot(candidates(:,1)-xy(1),candidates(:,2)-xy(2))>10)
            candidates(end+1,:)=[xy,r]; %#ok<AGROW>
        end
    end
end
end
end
