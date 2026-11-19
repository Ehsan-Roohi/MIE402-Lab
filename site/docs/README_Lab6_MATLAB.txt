LAB 6 - RADIOMETER: ANALYZE SEPARATE CLIPS

Two stages only: common Stage A, then the Stage B task in your group row
in the laboratory guide. Use the eight A/B rows in the log.
Each stage includes one continuous phone video. Two-bulb groups keep both
rotors in view on each camera and use a separate log per bulb (guide page 3).
Enter distance_m in metres, measured lux and all actual timing values.

IN LAB: Record and save the original A/B movies. Before leaving, replay
every saved file and confirm the rotor(s) and vane edges are visible after
OFF, the lamp-off cue is clear and coverage is complete. Record bulb IDs,
capture fps, lux and actual clip delays. Re-record unusable footage.
AT HOME: Do the MATLAB marking, RPM calculations, plots and report. Use
the optional Lab6_Check_Reversal.py and Lab6_Reversal_Check.md for a
second look at any suspected turn on a fixed-camera recording.

1. Unzip the complete MATLAB bundle into a single folder. Keep the original
   acquisition movies and the actual capture fps for each clip. Ignore the
   export playback fps when calculating physical time or rotation speed.
2. For each stage, keep on_start, on_late, off_start and off_late as the
   standard Chronos phases (up to 17 seconds per clip). Record the switch
   frame in on_start and off_start. Take on_late about 60 s after clip 1
   ends. Check all rotors 60 s after OFF. With a spherical bulb, save one
   17 s off_late in A and B starting about 65 s after OFF, even if it looks
   still. A pilot recoil occurred at 74-78 s after OFF. Use a clip already
   covering this window, or the next available clip if the camera is busy.
   For other bulbs, record off_late if moving or log the still check time.
   Count each clip once. Log actual switch-to-first-frame delays.
   Before switching off, start one fixed phone in normal-speed video mode
   with flash off. Include a visible lamp-off cue and both rotors in paired
   tests. Start at least 5 s before OFF and keep filming through all pauses
   and Chronos saves. Record at least 90 s after OFF. The tall-bulb reversal
   team records at least 150 s after OFF in both A and B. If either rotor is
   still moving at 150 s, continue until both stop.
   Tall-bulb reversal team, in both A and B: keep both rotors in the shot.
   Start off_start just before OFF. Record up to 17 s, then save and re-arm.
   Take three more 17 s clips, each as soon as Chronos is ready. Name them
   A_off_event01 to A_off_event03 (use B for Stage B). Log each actual start
   time after OFF. The phone must keep recording during every save gap.
   Use a clip already covering off_late rather than counting it twice.
   Other teams take extra Chronos clips near a turn if needed. Retain the
   actual phone filename, e.g. A_phone_off.mov.
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
   Tall-bulb reversal team: for each bulb in A and B, report the first
   sustained reversal time from the phone and the fastest measured reverse
   interval in rpm. The lamp-on direction is positive. For an interval seen
   turning backward, give the MATLAB rpm a minus sign. Use the most negative
   verified interval, with its clip and passage frames. If too few passages
   are visible, report speed unavailable and keep the video observation.
7. If you can fit a decay constant, use ln(rpm) and elapsed time from one
   continuous positive-speed clip with a consistent direction. For a straight
   interval under negligible residual drive and linear loss, a negative slope
   gives T = -1/slope. Report the clip, fit window and T. If there are too few
   points or no defensible interval, record T unavailable.

8. After lab, check every rotor, including spherical bulbs, in the original
   A and B Chronos clips. In the frame marker, use the arrow keys to compare
   a vane corner against the hub and a fixed glass or base feature. At
   1000 capture fps, 100-1000 frames span 0.1-1 s. Use smaller steps near a
   turn. Check a second corner if visible. For suspected motion keep the clip
   name and three frame numbers (before, at and after the apparent turn).
   In a late clip, time since OFF = actual start delay + frame / capture fps.
   Frame 0 is the first saved frame. Record sustained reversal, brief recoil,
   no recoil resolved in the stated Chronos window, or unclear. For the
   continuous phone video, state the last observed time. When motion is
   visible but crossings are insufficient for rpm, keep the observation and
   use insufficient for speed. A few degrees of recoil may give no crossing.

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
