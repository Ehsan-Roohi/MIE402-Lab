MIE 402 Lab 4 - Fall 2026
Free-response analysis code

File:
  MIE402_Lab4_Analyze_Free_Response.m

Before running:
1. Preserve the original Vernier CSV file.
2. Record the total moving mass, both spring stiffnesses, damper count,
   sample rate, initial displacement, and run description.
3. Place the MATLAB file anywhere you can write files.

Run:
1. Open MATLAB and run MIE402_Lab4_Analyze_Free_Response.m.
2. Select one raw Vernier CSV file.
3. Enter the requested mass, spring, and damper metadata.
4. Inspect the time trace, chosen peaks, logarithmic fit, and FFT.
5. The script creates a Lab4_results folder next to the raw CSV.

Required quality checks:
- At least several complete cycles are visible.
- The release does not show an obvious push or impact.
- Selected peaks have the same sign and decrease consistently.
- Log-fit R^2 and residual behavior are reported.
- The peak-spacing and FFT frequency estimates are reasonably close.
- For a cart between two springs, k = k_left + k_right.
- Total moving mass includes the cart and all attached moving pieces.

The spectrum is a displacement spectrum. Do not multiply it by 180/pi.
FFT confirms the dominant frequency near the damped natural frequency;
the decay fit supplies damping.
