function R = Lab6_Passage_Speed(frame, captureFPS, passagesPerRevolution)
% Consecutive verified passage frames -> interval speed. Base MATLAB.
% frame: original video frame numbers (0- or 1-based, consistently).
% captureFPS: actual acquisition fps, not slow-motion playback fps.
% passagesPerRevolution: number of the selected events in one full turn.
validateattributes(frame,{'numeric'},{'vector','real','finite','nonnegative'});
validateattributes(captureFPS,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(passagesPerRevolution,{'numeric'},{'scalar','integer','positive','finite'});
frame=double(frame(:));
assert(numel(frame)>=3,'Mark at least three consecutive passages.');
assert(all(diff(frame)>0),'Passage frames must increase strictly. Remove duplicates and check ordering.');
assert(all(abs(frame-round(frame))<1e-8),'Use integer frame numbers.');
t=(frame-frame(1))/captureFPS;
dt=diff(t); rpm=60./(passagesPerRevolution*dt);
% A large interval change needs video review. It may be real acceleration,
% a missed crossing, or a changed event definition. Never silently repair it.
ratio=max(dt(2:end)./dt(1:end-1),dt(1:end-1)./dt(2:end));
review=false(size(dt));
bad=find(ratio>1.8); review(bad)=true; review(bad+1)=true;
R=struct('frame',frame,'time_s',t,'interval_time_s',(t(1:end-1)+t(2:end))/2,...
    'interval_rpm',rpm,'omega_rad_s',rpm*2*pi/60,'review',review,...
    'mean_rpm',60*(numel(frame)-1)/(passagesPerRevolution*(t(end)-t(1))),...
    'capture_fps',captureFPS,'passages_per_revolution',passagesPerRevolution);
end
