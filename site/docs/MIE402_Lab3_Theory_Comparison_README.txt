LAB 3: EXPERIMENT VS THEORY — SIMPLE MATLAB GUIDE

FILE TO RUN: Run_Lab3_Compare_Theory.m
This compares YOUR saved experiment with the Lecture 04 double-pendulum
models. You do not need to record another video or write MATLAB code.

1. Download MIE402_Lab3_Theory_Comparison_MATLAB.zip and extract ALL files.
   In MATLAB, select the extracted folder as Current Folder.
2. Open Run_Lab3_Compare_Theory.m and click Run. Do not run the helper files.
3. Choose your saved ExpData MAT file, or the Lab3_Analysis.mat produced
   by the experimental-data analysis. Select a MAT file, not the video.
4. Enter YOUR group's measurements in the dialog:
   L1 [mm]: fixed pivot CENTER to moving middle-joint CENTER.
   L2 [mm]: middle-joint CENTER to bottom-bob CENTER.
   m1 [g]: upper bar alone. m2 [g]: lower bar alone.
   M1 [g]: middle bob/joint and its hardware, excluding the bars.
   M2 [g]: bottom bob and its hardware, excluding the bars.
   Enter grams and millimeters; conversion to kg and m is automatic.
   Check the suggested tracked lengths against your own measurements.
   Do not copy another group's values or count the bars twice.
5. In the preview, read a start/end time from the ORIGINAL MAT time axis.
   Choose motion after your hand has released the apparatus. The start
   may be mid-swing: the code estimates initial angles AND speeds from
   the data. You do not need to guess an initial angle or set speed to zero.
6. Open the output folder ending _TheoryComparison next to your input MAT.
   Repeat with each trial and that trial's appropriate measurements.

FIGURES TO USE IN YOUR REPORT
01_angles_theory_overlay.png: main experiment/theory comparison for both
links. Blue dots = measured; red = nonlinear; purple dashed = small-angle.
02_observed_only_residuals.png: angular disagreement versus time.
03_spectra_theory_overlay.png: compare frequency content; read the marked
small-angle frequencies and measured FFT bin. The second mode need not
appear as a strong experimental peak in every release.
04_energy_model_check.png: explain only if relevant to your report;
this is model-based energy, not a direct energy measurement.
Use PNG files in Word/PDF; FIG files can be edited in MATLAB. Label the
trial, release condition, masses, lengths and compared time interval.
READ_COMPARISON.txt gives modal frequencies and angular RMSE for both
models. Explain agreement near the start and any later phase/amplitude
differences. A larger-angle release can invalidate the small-angle model.
These instructions support the report requirements in the lab guide.

IF IT DOES NOT RUN
Extract the whole ZIP first. Keep all five files in one Current Folder.
A missing tracked joint cannot be recovered by theory comparison; review
the tracking output and retrack the existing video if needed.
Do not use pixel-only coordinates without physical length calibration.
Use actual camera capture timing, not slow-motion playback fps.

The two models use the same measured inputs and data-derived initial
state. No mass, damping, time or phase adjustment forces a match. The
nonlinear baseline omits friction and air drag. Short-gap estimates are
excluded from error metrics; long missing intervals stay blank.

DETAILED MODEL AND OUTPUT REFERENCE
===================================
MIE 402 LAB 3 — COMPARE MEASUREMENTS WITH LECTURE 04 THEORY

PURPOSE
Run_Lab3_Compare_Theory.m overlays your experimental motion with:
1. The full nonlinear compound-pendulum model, including uniform bar masses.
2. The analytical small-angle solution of M0*qdd + K*q = 0.
Both predictions use the SAME entered parameters and initial state.
Neither model is fitted to force agreement with the measured trajectory.
The baseline omits friction and air drag, as in Lecture 04.

BEFORE STARTING
Have your group's four measured masses and two center-to-center lengths.
Keep all extracted MATLAB files together. Select a calibrated ExpData MAT
or a saved Lab3_Analysis.mat. Pixel-only video-tracker files must first be
converted using actual capture timing and a measured physical length.
This comparison code uses base MATLAB/compatible GNU Octave operations;
the preceding VIDEO tracker has separate image/video requirements.

WHAT EACH STUDENT GROUP DOES
1. Extract the comparison ZIP and set that folder as MATLAB's Current Folder.
2. Open Run_Lab3_Compare_Theory.m and click Run, or type:
     Run_Lab3_Compare_Theory
3. Select your trial's ExpData MAT or Lab3_Analysis.mat. If you select raw
   ExpData, the supplied experimental-analysis code first checks tracking
   and saves its ordinary quality-control plots.
4. Enter SIX measured values in the dialog. Dialog units are mm and grams:
   L1 [mm]: fixed pivot center to upper moving joint center.
   L2 [mm]: upper moving joint center to lower bob center.
   m1 [g]: uniform upper BAR alone.
   m2 [g]: uniform lower BAR alone.
   M1 [g]: lumped upper joint/bob and associated hardware, excluding bars.
   M2 [g]: lumped lower bob and associated hardware, excluding bars.
   Include hardware once in the appropriate assembly; do not count it twice.
   If your recorded assembly mass includes a bar, subtract that bar's
   measured mass to obtain the separate lumped bob/hardware input.
   Suggested lengths come from the tracked-coordinate medians: check them
   against your measurements. No default/example masses are inserted.
   The code converts dialog inputs to meters and kilograms internally.
5. Inspect the measured-angle preview and choose a start/end time in the
   ORIGINAL MAT time axis. Start AFTER the hand has released the apparatus.
   A hand-held interval does not satisfy the free-motion model. The code
   advances to a short fully observed window if the requested start is bad,
   and records the actual starting time in READ_COMPARISON.txt.
6. Read the output folder ending _TheoryComparison. Repeat for each trial.

INITIAL CONDITIONS
theta1 and theta2 are ABSOLUTE link angles from downward vertical; the
relative moving-joint angle is theta2-theta1. omega1 and omega2 are signed
angular velocities d(theta1)/dt and d(theta2)/dt in rad/s.
The default code estimates ONLY the initial angles and speeds from a
local quadratic angle fit over approximately 25 ms of observed data.
It does not fit masses, lengths, damping, later phase, or later amplitude.
The same initial state is given to both models. A manually supplied state
is also supported, but must correspond to the selected starting frame.

CONNECTION TO LECTURE 04
The nonlinear equation at each instant is:
  [I11, C*cos(theta1-theta2); C*cos(theta1-theta2), I22] * [alpha1; alpha2]
    = [-C*sin(theta1-theta2)*omega2^2 - G1*sin(theta1);
       +C*sin(theta1-theta2)*omega1^2 - G2*sin(theta2)].
The supplied MIE402_Lab3_RHS.m evaluates this equation for ode45.
  I11 = (m1/3 + M1 + m2 + M2)*L1^2
  I22 = (m2/3 + M2)*L2^2
  C   = (m2/2 + M2)*L1*L2
  G1  = (m1/2 + M1 + m2 + M2)*g*L1
  G2  = (m2/2 + M2)*g*L2
For small angles about the DOWNWARD equilibrium:
  M0 = [I11,C;C,I22]; K = diag(G1,G2).
  K*phi_i = Omega_i^2*M0*phi_i; f_i = Omega_i/(2*pi).
Omega_i is a small-angle MODAL frequency in rad/s. It is different from
the time-dependent link speed omega_i(t). Two modes are model properties;
one release can excite one weakly, and two FFT peaks are not guaranteed.
The code constructs the analytical two-mode time solution using the
entered initial state. A large-angle run is outside the linear model's
assumptions; its linear curve is a reference showing that limitation.

OUTPUTS AND REPORT USE
01_angles_theory_overlay.png/.fig:
  Observations, nonlinear prediction, and small-angle prediction for BOTH
  links on the same time axis. Short-gap estimates are separate markers.
  Plots use principal orientations, with wrap discontinuities left blank.
02_observed_only_residuals.png/.fig:
  Signed circular angular errors, experiment minus each prediction.
  A full revolution is not counted as a 360-degree orientation error.
03_spectra_theory_overlay.png/.fig:
  All three signals on the SAME longest jointly observed interval, same
  timestamps and Hann window. The measured peak bin and bin spacing are
  stated; dotted lines mark the two SMALL-ANGLE predicted frequencies.
  If the motion includes full rotations, sin(angle) is used for ALL three
  spectra and labeled dimensionless. Otherwise amplitudes are radians.
04_energy_model_check.png/.fig:
  Experiment-derived mechanical energy under the entered mass/length
  model, and ideal nonlinear prediction. This uses differentiated angles;
  it is a diagnostic, not a direct energy measurement or proof of drag.
Lab3_Theory_Comparison.mat, theory_overlay.csv:
  Numeric observations, predictions, flags, errors, settings and provenance.
modal_frequencies_and_shapes.csv:
  Both small-angle frequencies and normalized mode shapes.
spectra_same_interval.csv:
  The overlaid numerical spectra, when the interval has enough observations.
READ_COMPARISON.txt:
  Entered SI parameters, initial state/source, actual interval, full-interval
  and first-second circular RMSE, FFT resolution and solver energy drift.

WHAT TO DISCUSS
Compare early timing, angle amplitudes, phase relationships and spectra.
For small releases, discuss the two small-angle modes and excitation.
For larger releases, discuss where the linear approximation loses value.
Long-time disagreement can involve friction/drag, initial-state errors,
calibration, out-of-plane motion, mass distribution or tracking. A large
difference alone does not prove chaos or identify air drag separately.
No bar charts or automatic tuning are needed. Use the actual overlays.

QUALITY LIMITS
Metrics exclude interpolated points. Unresolved gaps stay blank.
FFT uses the longest common interval containing observed points only.
An entirely unobserved joint cannot be compared with theory as measured
motion; retrack that existing video first. Frequency resolution is 1/T
for the selected record; zero padding is not used to imply finer resolution.
Energy conservation checks the numerical ideal solver, not model accuracy.

OPTIONAL BATCH INPUTS (SI UNITS; DIFFERENT FROM DIALOG UNITS)
  cfg.p = struct('L1',L1_m,'L2',L2_m,'m1',m1_kg,'m2',m2_kg,...
                 'M1',M1_kg,'M2',M2_kg,'g',9.81);
  cfg.parametersMeasured = true;
  cfg.parameterSource = 'Group measured values and calibrated tracking';
  cfg.timeRange = [startTime_s,endTime_s];
  R = Run_Lab3_Compare_Theory('trial.mat',cfg);
If using assumed parameters for a demonstration, set parametersMeasured=false
and describe the assumption. Figures and the summary then state ILLUSTRATIVE.
That demonstration does not replace your group's measured-parameter report.
