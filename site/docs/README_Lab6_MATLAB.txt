LAB 6 - RADIOMETER

1. Download and unzip the complete MATLAB bundle into one folder.
2. Run Mark_Lab6_Passage_Frames.m to view and mark original frames. Observe
   one complete revolution. Define ONE repeatable crossing of a fixed line.
   A uniquely identifiable vane gives p=1 event per revolution. If counting
   every vane, verify how many identical events occur per full turn. Do not
   assume p=4 just because four vanes are visible. Front/back appearances can
   create extra events. Do not add a physical marker to the sealed device.
3. Save consecutive crossing frame numbers in one column named frame, using
   the template. REPLACE ALL demonstration numbers with your measurements.
   At least 10 events are recommended. Use the same crossing direction.
4. Open Run_Lab6_Radiometer.m in MATLAB and click Run. Select the CSV/Excel
   file. Enter actual camera CAPTURE fps and your verified p. Do not enter
   the slow-motion file's playback fps. Recover capture settings from your
   run log/camera before reporting a physical rpm.
5. The script exports two panels, interval_speed.csv, a MAT result and a
   summary beside your table. Red circles require video review. Check missed
   passages and changing speed. Never replace a missed revolution with zero.
6. For a steady-speed comparison, create a separate table containing only a
   settled interval. Keep the complete recording for the transient plot.
7. Repeat for each light setting. Plot steady rpm against measured lux with
   separate symbols for repeats. Keep lamp type, geometry and meter orientation
   fixed. Lux is a photometric measure, not irradiance in W/m^2.

EXAMPLE ONLY: template frames with 1000 capture fps and p=4 give 60 rpm.
The supplied table is synthetic and must not be presented as laboratory data.
Requires MATLAB R2020b or later (base MATLAB). No Curve Fitting/Signal toolbox.
This tool analyzes verified passage frames; it does not automatically track vanes.
