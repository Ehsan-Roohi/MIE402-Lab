function [summary,intervals] = Lab6_Analyze_Clips(logTable,baseFolder)
% Analyze independently recorded clips on two clocks: since ON and since OFF.
% Each row specifies one clip (or a documented observation with no clip).
required = ["run_id","clip_phase","passage_csv","status","capture_fps",...
    "passages_per_revolution","lux","distance_m","switch_frame","delay_s"];
assert(all(ismember(required,string(logTable.Properties.VariableNames))),...
    'Use the current Lab6_Comparison_Log.csv headers for separate clips.');
assert(height(logTable)>0,'The clip log is empty.');

runID = strtrim(string(logTable.run_id));
phase = lower(strtrim(string(logTable.clip_phase)));
status = lower(strtrim(string(logTable.status)));
assert(all(~ismissing(runID) & strlength(runID)>0),'Enter a run_id on each row.');
startClip = ismember(phase,["on_start","off_start"]);
lateClip = ismember(phase,["on_late","off_late"]);
assert(all(startClip | lateClip),'Use on_start, on_late, off_start or off_late.');
assert(all(ismember(status,["recorded","stationary","insufficient","not_run"])),...
    'Use recorded, stationary, insufficient or not_run in the status column.');
[~,uniqueRows] = unique(table(runID,phase));
assert(numel(uniqueRows)==height(logTable),'Use a single row for each run_id and phase.');
clock = repmat("lamp_off",height(logTable),1);
clock(startsWith(phase,"on_")) = "lamp_on";
state = status;
rpm = nan(height(logTable),1);
coveredStart = rpm;
coveredEnd = rpm;
nIntervals = zeros(height(logTable),1);
nReview = nIntervals;
intervals = table('Size',[0 10],...
    'VariableTypes',{'string','string','string','double','double','double','double','double','double','logical'},...
    'VariableNames',{'run_id','clip_phase','clock_reference','first_frame','last_frame',...
    'interval_start_s','interval_end_s','interval_midpoint_s','interval_rpm','review'});

for i = 1:height(logTable)
    if status(i)=="not_run"
        continue;
    end
    distance = numberAt(logTable.distance_m,i);
    lux = numberAt(logTable.lux,i);
    assert(isfinite(distance) && distance>=0,'Row %d needs a nonnegative distance_m.',i);
    assert(isfinite(lux) && lux>=0,'Row %d needs measured lux.',i);
    delay = numberAt(logTable.delay_s,i);
    if lateClip(i) && (status(i)=="recorded" || status(i)=="stationary")
        assert(isfinite(delay) && delay>=0,...
            'Row %d needs elapsed delay_s from the matching lamp switch.',i);
    end
    if status(i)~="recorded"
        continue;
    end

    fps = numberAt(logTable.capture_fps,i);
    p = numberAt(logTable.passages_per_revolution,i);
    assert(isfinite(fps) && fps>0,'Row %d needs actual capture_fps.',i);
    assert(isfinite(p) && p>0 && p==round(p),'Row %d needs integer passages per revolution.',i);
    if startClip(i)
        switchFrame = numberAt(logTable.switch_frame,i);
        assert(isfinite(switchFrame) && switchFrame>=0 && switchFrame==round(switchFrame),...
            'Row %d needs the zero-based switch_frame in that clip.',i);
        assert(switchFrame<=ceil(17*fps),'Row %d switch_frame exceeds the 17 s clip.',i);
        offset = -switchFrame/fps;
    else
        offset = delay;
    end
    passageFile = strtrim(string(logTable.passage_csv(i)));
    assert(~ismissing(passageFile) && strlength(passageFile)>0,...
        'Row %d needs a passage_csv, or change its status.',i);
    if ~isfile(passageFile)
        passageFile = fullfile(baseFolder,passageFile);
    end
    assert(isfile(passageFile),...
        'Row %d passage file not found. Check its name or enter the appropriate status.',i);
    marks = readtable(passageFile,'VariableNamingRule','preserve','TextType','string');
    assert(ismember('frame',marks.Properties.VariableNames),'Each passage CSV needs a frame column.');
    frames = str2double(string(marks.frame));
    assert(all(isfinite(frames) & frames>=0 & frames==round(frames)) && all(diff(frames)>0),...
        'Row %d needs strictly increasing nonnegative integer frames.',i);
    assert(all(frames<=ceil(17*fps)),...
        'Row %d contains frames outside a 17 s clip. Check capture fps and frame numbering.',i);

    % A start clip may include pre-switch footage. Retain only complete
    % crossing intervals with both endpoints on or after the switch.
    frames = frames(frames/fps+offset>=0);
    if numel(frames)<3
        state(i) = "insufficient";
        continue;
    end
    result = Lab6_Passage_Speed(frames,fps,p);
    elapsed = result.frame/fps+offset;
    rpm(i) = result.mean_rpm;
    coveredStart(i) = elapsed(1);
    coveredEnd(i) = elapsed(end);
    n = numel(frames)-1;
    nIntervals(i) = n;
    nReview(i) = sum(result.review);
    oneClip = table(repmat(runID(i),n,1),repmat(phase(i),n,1),repmat(clock(i),n,1),...
        frames(1:end-1),frames(2:end),elapsed(1:end-1),elapsed(2:end),...
        (elapsed(1:end-1)+elapsed(2:end))/2,result.interval_rpm,result.review,...
        'VariableNames',intervals.Properties.VariableNames);
    intervals = [intervals;oneClip]; %#ok<AGROW>
end
logTable.run_id = runID;
logTable.clip_phase = phase;
summary = [logTable,table(clock,state,rpm,coveredStart,coveredEnd,nIntervals,nReview,...
    'VariableNames',{'clock_reference','analysis_status','mean_rpm','covered_start_s',...
    'covered_end_s','measured_intervals','intervals_to_review'})];
end

function value = numberAt(column,i)
value = str2double(string(column(i)));
end
