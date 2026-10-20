MIE 402 LAB 3 -- MATLAB EXPERIMENTAL-DATA ANALYSIS
Prof. Ehsan Roohi, Fall 2026. Updated 20 October 2026.

STUDENT WORKFLOW (MATLAB)
1. Download the updated MATLAB bundle from the Lab 3 course page and extract it.
   Replace your older copy of Run_Lab3_ExpData_Analysis.m; do not run an old copy
   from another folder. This experimental-analysis script is self-contained.
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

REQUIREMENTS AND VALIDATION
MATLAB R2019b or newer (tiledlayout, writematrix and implicit expansion).
No optional signal-processing or curve-fitting toolbox is used.
The corresponding Python algorithm and Colab computations were tested on two real
experimental MAT files. MATLAB is unavailable on the preparation computer, so
this MATLAB script has not yet been executed in MATLAB. A laboratory-computer
runtime check with a known MAT file is still required before calling it MATLAB-
verified. Optional Colab/Python files remain available for comparison/troubleshooting.
