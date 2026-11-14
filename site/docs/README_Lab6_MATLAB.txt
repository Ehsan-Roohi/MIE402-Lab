LAB 6 - RADIOMETER: ANALYZE SEPARATE CLIPS

1. Unzip the complete MATLAB bundle into a single folder. Keep the original
   acquisition movies and the actual capture fps for each clip. Ignore the
   export playback fps when calculating physical time or rotation speed.
2. For each lamp gap, label clips on_start, on_late, off_start and off_late.
   Begin recording before the light switch for on_start and off_start. For
   on_late and off_late, use a stopwatch to log the actual elapsed seconds from
   the matching switch to the first saved frame. Wait about 60 s after the
   previous clip ends, so delay_s is usually about 77 s from the switch.
   If the rotor has stopped at the delayed off check, record the observation
   and elapsed time. You can skip that movie.
3. Run Mark_Lab6_Passage_Frames.m for each movie. Choose one reference line
   and one repeatable crossing event. Use the same event definition for the
   series. p is the number of selected events in one full revolution. Follow
   one identifiable vane for p = 1. If you count every vane, verify the number
   of events over a full turn, including their angular spacing. A rotor with
   four vanes does not by itself establish p = 4. Never add a marker to the
   sealed bulb. Keep consecutive marks in a single direction and in one file.
   The marker tool numbers frames from zero. The script writes a passage CSV.
4. Open Lab6_Comparison_Log.csv. Match the movie and passage filenames and
   enter actual capture_fps, passages_per_revolution, measured lux and gap.
   Rows for the same gap and repeat share a run_id. In the start clips enter
   switch_frame (zero-based index of the switch in that saved file). In the
   late clips enter delay_s (seconds from that switch to the first saved
   frame). Report the measured switch-to-frame delay, not just the wait. Add bulb and
   temperature information to the log as available.
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

Run_Lab6_Radiometer.m is also available for plots for a single marked clip.
Its time axis is relative to the first retained passage. Enter actual capture
fps and verified p when prompted. The example passage template is synthetic.
Requires base MATLAB R2020b or later. No automatic vane tracking.
