MIE 402 LAB 3 -- MATLAB EXPERIMENTAL-DATA ANALYSIS
Prof. Ehsan Roohi, Fall 2026

RUN THE ANALYSIS
1. Download the MATLAB bundle from the Lab 3 course page and extract it.
2. In Pendulum Motion Analyzer V4, track the two bob centers and save ExpData.mat.
   The columns are time_s, x1_mm, y1_mm, x2_mm, y2_mm. Positions are relative to
   the fixed pivot, with x positive rightward and y positive upward.
3. Open Run_Lab3_ExpData_Analysis.m in MATLAB, click Run, and select the MAT file.
   Run the main file rather than its local helper functions. Repeat for each trial.
4. Inspect the tracking-geometry diagnostic, angle histories, angular velocities
   and spectra before selecting figures for your report.

OUTPUT FILES
The <recording>_Lab3_results folder beside your input contains:
- 01_tracking_geometry.png: tracked lengths and reference lengths.
- 02_angles_and_velocity.png: principal angles and angular velocities.
- 03_frequency_spectra.png: both spectra over a common time interval.
- 04_continuous_rotation.png: continuous angles within connected data segments.
- Editable .fig versions of the figures.
- analysis_with_quality_flags.csv: raw coordinates, results and quality flags.
- link1_spectrum.csv and link2_spectrum.csv: frequency and amplitude tables.
- Lab3_Analysis.mat: analysis variables for further work in MATLAB.

INTERPRETING THE RESULTS
Angles are measured from the downward vertical. Principal angles lie between
-180 and 180 degrees; continuous angles can exceed this range during full turns.
Winding is not joined across unresolved gaps. Check the original video when
interpreting rotations and overlapping bob images.

Short internal gaps are estimated only within the duration and angle limits
specified at the top of the file. Estimates are marked; longer gaps and missing
endpoints remain blank. A complete trace through a long gap requires review or
retracking of the original video.

The default length screen is +/-20% about a reference length. This is a coarse
quality check, not a calibration uncertainty. If independently measured lengths
are available, set measuredLengthsMM=[L1 L2], in millimeters, near the top.

Angular velocity uses a 21 ms local-polynomial derivative. Neighborhoods affected
by gap estimates and segment boundaries are excluded. Both FFTs use the same
longest joint-valid interval. Check the interval and frequency-bin spacing.
For a rotating segment, a spectrum may use sin(theta), labelled dimensionless,
rather than an accumulating angle. Large-angle peaks are not automatically the
two small-angle modal frequencies.

IN YOUR REPORT
State axes and units, original capture frame rate, calibration, measured masses
and lengths, retained analysis interval, estimated or excluded points, and limits
of the measurements. Use capture fps rather than slow-motion playback fps.

THEORETICAL COMPARISON
Keep the model/simulation files together. Test_Lab3_Model.m checks the simulation
model and coordinate convention. Use Run_Lab3_Simulation.m with measured masses,
lengths and initial conditions for a prediction over the same physical interval.
The experimental analysis does not automatically fit or overlay that prediction.

MATLAB REQUIREMENTS
Base MATLAB operations using R2016b+ syntax. No optional curve-fitting or
signal-processing toolbox is required.
