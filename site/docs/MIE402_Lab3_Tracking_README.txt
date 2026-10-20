MIE 402 LAB 3 -- DOUBLE-PENDULUM TRACKING REPAIR
Prof. Ehsan Roohi, UMass Amherst, Fall 2026
20 October 2026

START WITH THE PROVIDED COLAB NOTEBOOK
Open MIE402_Lab3_Tracking_Analysis.ipynb in Google Colab, run the cells in order,
and upload your existing ExpData MAT file when prompted. All code is supplied.
Analyze the usable parts of your existing recording; inspect tracking warnings.
Download the generated results ZIP. Original files are not overwritten.

LOCAL PYTHON
python -m pip install -r requirements.txt
python MIE402_Lab3_Analyze_ExpData.py your_recording.mat --output your_results
The ZIP input option accepts exactly one MAT file; a MAT directly is preferred.

MATLAB
Run Run_Lab3_ExpData_Analysis.m and select your existing ExpData MAT file.
This is the main SCRIPT. Do not run its local helper functions separately.
The MATLAB port uses base MATLAB operations and does not call sineFit.
The matching Python implementation was actually run on both supplied MAT files.
MATLAB itself was not available; the MATLAB port is supplied for instructor
testing, not represented as a MATLAB-verified executable.

WHAT WAS WRONG
1. NaN checks alone miss finite but invalid tracking: both bob coordinates can
   be nearly identical, making the lower-link length nearly zero.
2. The former script aborts if the first/last tracking rows are missing. Missing
   end rows should remain missing; they do not invalidate the rest of a run.
3. A continuous angle from unwrap can legitimately reach -1000 degrees after
   multiple rotations. This number alone is not proof of failed tracking.
4. Differentiating raw jitter, coordinate failures or branch cuts creates
   artificial angular-velocity spikes.

WHAT THE NEW ANALYSIS DOES
- Preserves raw coordinates and original timestamps in the output CSV.
- Separately checks each link's finite coordinates and approximately constant
  length. Default +/-20% is a coarse QC screen, not an uncertainty estimate.
  Supply independently measured link lengths with --lengths-mm L1 L2 when known.
- Retains missing endpoints; never extrapolates them. Complete internal gaps
  are filled only if anchor separation is <=0.05 s and angular change <=60 deg.
  Short circular interpolation estimates are explicitly flagged in the CSV.
- Leaves longer or ambiguous gaps as NaNs; never joins winding across them.
- Reports principal orientation [-180,180] and continuous angle separately.
  The first is a coordinate convention; the second preserves genuine turns.
- Computes a 21 ms local-polynomial angular derivative and excludes derivative
  neighborhoods influenced by estimated samples and segment edges.
- Uses the SAME longest joint-valid interval for both Hann-windowed FFTs,
  with correct DC/Nyquist scaling and explicit time interval/bin spacing.
  If the selected segment includes full rotations, sin(theta), rather than a
  winding ramp, is used and labelled as dimensionless orientation.
- Does not fit the double-pendulum trace to one sine wave or force a small-angle
  model onto large-angle/rotating motion.

WHICH FIGURES TO USE
02_angles_and_velocity.png: principal orientation and filtered angular velocity.
03_frequency_spectra.png: spectra over the stated common time window.
04_continuous_rotation.png: discuss full turns and disconnected segments.
01_tracking_diagnosis.png: documents old processing and geometry failures.
The MATLAB script produces a geometry-only diagnostic with a similar name.
Report axes/units, retained interval, interpolated/rejected data, original capture
fps, and limitations. Dominant FFT bins are NOT automatically small-angle modes.

LIMITS
The code cannot reconstruct a hidden bob from a MAT file. For a complete trace
through a long missing interval, retrack the EXISTING video or verify manually.
Length screening cannot catch every wrong detection on a plausible circle, nor
validate the camera scale, pivot placement, capture timing or out-of-plane motion.
Check representative video frames, especially around full rotations or overlap.
The reference lengths inferred from each recording are QC estimates, not new
physical measurements. Original laboratory mass/length measurements still apply.


PUBLICATION AND VALIDATION
Python and notebook computations were tested on two real experimental MAT files.
Student recordings and their results are not included in this public package.
Use the tested Colab/Python workflow; the MATLAB port needs runtime validation.
