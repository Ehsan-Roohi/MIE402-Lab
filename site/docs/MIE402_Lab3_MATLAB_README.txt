MIE 402 LAB 3 -- MATLAB EXPERIMENTAL-DATA ANALYSIS
Prof. Ehsan Roohi, Fall 2026. Updated 20 October 2026.

STUDENT WORKFLOW (MATLAB)
1. Download the updated MATLAB bundle from the Lab 3 course page and extract it.
   Replace your older copy of Run_Lab3_ExpData_Analysis.m; do not run an old copy
   from another folder. This experimental-analysis file is self-contained.
2. Use Analyzer V4 as before to track the existing video and save ExpData.mat.
   If you already have that MAT file, start with step 3; no new video is needed
   to analyze its usable intervals. The Analyzer application itself is unchanged.
3. Open Run_Lab3_ExpData_Analysis.m in MATLAB and click Run. Select your MAT file.
   Do not run local helper functions separately. No sineFit is required.
4. Inspect the geometry diagnostic first: near-zero lower-link lengths indicate
   overlapping/incorrect bob detections. Review questionable points in the video.
5. Inspect angle and angular-velocity plots, the continuous-rotation plot, and
   the spectra. Figures (.png and editable .fig), CSV tables and Lab3_Analysis.mat
   are saved beside your input in <recording>_Lab3_results. Repeat for each trial.

UNDERSTANDING THE OUTPUT
- Missing endpoint rows remain missing; they no longer abort the entire record.
- Short internal gaps are estimated only within the stated duration/angle limits
  and explicitly flagged. Long or ambiguous gaps remain blank, never extrapolated.
- Principal orientation is between -180 and 180 degrees. Continuous rotation may
  exceed that range during real full turns. Do not clip it or force one sine fit.
- Both FFTs use the same longest joint-valid interval. Check the reported interval
  and frequency-bin spacing. During rotations the spectrum may use sin(theta),
  labelled as dimensionless, instead of a continuous-angle winding ramp.
- Peaks during large-angle motion are not automatically small-angle modal values.
- State the retained interval, rejected/estimated data and limitations in the report.
- Default +/-20% length screening is coarse quality control, not uncertainty.
  Set measuredLengthsMM=[L1 L2] at the top if independent lengths in mm are known.
- Long gaps require review/retracking of the EXISTING video for a complete trace.
  The script cannot reconstruct missing positions from the MAT file alone.

OTHER MATLAB FILES
Keep the complete model/simulation files together. Run Test_Lab3_Model.m for the
simulation model, then Run_Lab3_Simulation.m with measured masses and lengths.
That model test does not validate experimental tracking or this analysis script.

REQUIREMENTS AND EXECUTION CHECK
The numerical entry point uses base MATLAB operations (R2016b+ syntax).
No optional curve-fitting or signal-processing toolbox is required.
The actual Run_Lab3_ExpData_Analysis.m was executed, without numerical shims,
in GNU Octave 11.3.0 on two original experimental MAT files. Both runs completed
and produced four PNG figures, four editable figure files, CSV tables and a MAT
result. Angles, raw data, geometry checks, gap flags and FFTs matched the separate
Python implementation; maximum angular-velocity difference was below 2e-11 rad/s.
This is an actual .m-language execution test, not a MATLAB-runtime or editor-UI
test: MathWorks MATLAB is not installed on the preparation computer.
Students continue to use MATLAB in the laboratory. Colab is optional.
