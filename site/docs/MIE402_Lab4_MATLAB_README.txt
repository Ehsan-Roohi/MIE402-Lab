MIE 402 · Lab 4 · Free response of a spring–cart system
University of Massachusetts Amherst · Prof. Ehsan Roohi · Fall 2026

MAIN MATLAB ENTRY SCRIPT (run this file, not individual helpers):
    MIE402_Lab4_Analyze_Free_Response.m

Course guide:
    https://ehsan-roohi.github.io/MIE402-Lab/docs/MIE402_Lab4_Analysis_Workflow_Fall2026.html

PRIOR TO ANALYSIS
1. Save all raw Vernier Graphical Analysis CSV exports, one per case.
2. Record actual total moving mass m [kg]: cart + masses + moving attachments,
   including any added magnetic hardware.
3. Record spring IDs and independently calibrated kLeft and kRight [N/m].
4. Record the number of magnetic-brake MAGNETS (not brake assemblies),
   acquisition rate [Hz], release displacement, and condition ID.
5. Confirm the local seven-case procedure: base, two added-mass cases,
   two added-magnet cases (2 and 4), and two alternate spring pairs.

RUN
1. Open and run MIE402_Lab4_Analyze_Free_Response.m in MATLAB.
2. Pick one raw Vernier CSV. The script plots raw position and asks for the
   after-release interval. Exclude hand contact, impact and clipped data.
3. Enter mass and measured spring constants, magnet count and exported
   position unit (m/cm/mm). Verify time samples are sufficiently uniform.
4. Inspect selected positive peaks. If late peaks are close to sensor noise,
   shorten the analysis interval and rerun.
5. The script reports peak-spacing f_d, FFT f_peak, alpha, zeta,
   omega_n-derived f_n, c=2m*alpha, and predicted f_n from measured springs.
6. Inspect the time record, positive peak envelope, log-peak regression,
   full-response fit residual and one-sided displacement spectrum.
7. Save the summary CSV and plots produced in Lab4_results beside the raw CSV.

INTERPRETATION
k_eq = kLeft + kRight. In the underdamped viscous approximation,
omega_n = sqrt(k_eq/m) [rad/s], alpha = c/(2m) [1/s],
omega_d = sqrt(omega_n^2-alpha^2) [rad/s], zeta = alpha/omega_n.
A fitted ln(peak amplitude/1 m) versus time line has slope -alpha.
Same-sign peak spacing measures T_d = 2*pi/omega_d [s].
FFT peak is a cross-check, not an estimate of damping from spectral height.
Initial-amplitude differences, bin spacing, finite record and noise matter.
Residual damping remains without added magnetic brake magnets.

QUALITY AND UNCERTAINTY
- Confirm peak signs and count actual complete cycles, not peak count.
- Review drift rather than blindly removing a linear trend.
- Check the actual spring constants and mass in each configuration.
- Check peak selection, slip, friction, spring slack, and residual patterns.
- Report units and reasonable precision, not more digits than measured.
- Clearly distinguish historical student plots from model illustrations.

VALIDATION STATUS
The script is a MATLAB main script with no separate required helper entry.
MATLAB execution against actual laboratory CSV records has NOT been verified
by the assistant in this revision. Inspect its outputs with the GTA and compare
against known values before relying on it for graded analysis.
