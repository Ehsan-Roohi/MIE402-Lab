LAB 6 - RADIOMETER: ANALYZE SEPARATE CLIPS

Two stages only: common Stage A, then the Stage B task in your group row
in the laboratory guide. Use the eight A/B rows in the log.
Each stage includes one continuous phone video. Two-bulb groups keep both
rotors in view on each camera and use a separate log per bulb (guide page 3).
Enter distance_m in metres, measured lux and all actual timing values.

1. Unzip the complete MATLAB bundle into a single folder. Keep the original
   acquisition movies and the actual capture fps for each clip. Ignore the
   export playback fps when calculating physical time or rotation speed.
2. For each stage, keep on_start, on_late, off_start and off_late as the
   standard Chronos phases (up to 17 seconds per clip). Record the switch
   frame in on_start and off_start. Take on_late about 60 s after clip 1
   ends. Check off_late 60 s after lamp OFF. If any rotor moves, record it.
   Count a clip already spanning the check once as off_late. Log actual
   switch-to-first-frame delays. If all are still, record the check time.
   Before switching off, start one fixed phone in normal-speed video mode
   with flash off. Include a visible lamp-off cue and both rotors in paired
   tests. Record from at least 5 s before OFF through at least 90 s after OFF,
   including pauses and Chronos saves. As a rotor slows or starts to reverse,
   take extra Chronos clips as needed. Save, re-arm and log each start time
   from OFF. Name these clips A_off_event01, A_off_event02, etc. Use B for
   Stage B. Retain the actual phone filename, e.g. A_phone_off.mov.
3. Run Mark_Lab6_Passage_Frames.m for each Chronos clip used for speed. Choose one
   reference line and one repeatable crossing event. Use the same event definition for the
   series. p is the number of selected events in one full revolution. Follow
   one identifiable vane for p = 1. If you count every vane, verify the number
   of events over a full turn, including their angular spacing. A rotor with
   four vanes does not by itself establish p = 4. Never add a marker to the
   sealed bulb. Keep consecutive marks in a single direction and in one file.
   The marker tool numbers frames from zero. The script writes a passage CSV.
4. Open Lab6_Comparison_Log.csv. Match the movie and passage filenames and
   enter actual capture_fps, passages_per_revolution, measured lux and gap.
   Keep run_id A for the reference and B for your group task. In start clips enter
   switch_frame (zero-based index of the switch in that saved file). In the
   late clips enter delay_s (seconds from that switch to the first saved
   frame). In the off_start notes, list the phone file, initial direction,
   first visible pause and first clear reversal in seconds since OFF. Use the
   phone timestamp at OFF as zero. If this bulb shows no reversal, enter "no reversal
   observed through __ s". Use "unclear" if the view cannot resolve direction.
   List each extra Chronos filename and its actual start time in the same notes.
5. Keep status = recorded for valid marked movies. The analysis reports an
   insufficient result if fewer than three qualifying crossings are marked.
   Use stationary for a visually confirmed stationary rotor. For an omitted
   delayed off movie enter stationary and the observed delay_s. Use
   insufficient if the rotor moved but crossings cannot be resolved or there
   are too few crossings to use. Use not_run for other omitted clips. The
   analysis leaves the mean RPM blank (NaN) for rows without speed estimates.
6. Run Compare_Lab6_Illumination_Runs.m and choose the completed comparison log.
   Lab6_Comparison_Results contains Lab6_Clip_Summary.csv,
   Lab6_Clip_Intervals.csv and the figures. Lamp-on and lamp-off times are on
   separate axes. Dots show within-clip intervals. The gaps between recordings
   contain no speed data. A mean speed covers first-to-last retained passage
   within one clip. Compare late-on mean RPM across lux at similar delays and
   thermal conditions. Review red X marks against the footage. The per-clip
   speed is unsigned. Document the observed direction and any reversal, and
   use only a single direction in a passage file.
7. If you can fit a decay constant, use ln(rpm) and elapsed time from one
   continuous positive-speed clip with a consistent direction. For a straight
   interval under negligible residual drive and linear loss, a negative slope
   gives T = -1/slope. Report the clip, fit window and T. If there are too few
   points or no defensible interval, record T unavailable.

Use Run_Lab6_Radiometer.m for extra Chronos clips. Save a separate passage CSV
for each direction before marking the next segment. This script uses time
relative to the first retained passage. Enter actual Chronos capture fps and
verified p. Use the phone's real-time timestamps for pause and reversal.
The example passage template is synthetic.
Requires base MATLAB R2020b or later. No automatic vane tracking.

TWO BULBS IN ONE MOVIE
Mark R1 first and move its generated passage CSV into folder R1 before
marking R2: the marker otherwise overwrites the same output filename.
Move the second CSV into folder R2. Keep one A/B comparison log per bulb.
Use full video and passage CSV paths; share switch frames and clip delays.
Enter each bulb's own lux, ID and passage marks. Run the comparison script
once per bulb. Compare each bulb with its own Stage A result.
