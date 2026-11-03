MIE 402 - Lab 5: forced response

1. Unzip the bundle into a writable folder. Keep the three analysis .m files together.
2. Open Run_Lab5_Forced_Response.m in MATLAB and click Run. Do not run helpers.
3. Select impulse/free decay or harmonic sweep. Enter YOUR measured total moving
   mass in kg and the two spring stiffnesses in N/m. Include mounted damper mass.
4. Select CSV or Excel files (Ctrl-click to select several). Use one run per file.
   For Excel choose the worksheet. Enter time/position column numbers, e.g. [1 2],
   or [] for automatic detection when there is only one clear pair of headers.
   If the export has an index column, the correct pair may be [2 3].
5. Enter start/end times read from your Vernier graph, then position units (m is
   the default). Impulse: start after the hand has left the cart. Harmonic: use
   a settled interval of at least five cycles, preferably ten or more.
6. Harmonic only: enter measured rpm, input peak-to-peak displacement in METERS,
   and damping c measured with the SAME mass and damper configuration. If c is
   unknown, first record a free decay with the drive stopped and analyze it
   with mode 1. Do not reuse an undamped-cart c after adding magnetic dampers.
7. Results are saved beside the raw data in Lab5_Results: annotated PNG figures,
   fit CSVs, a summary CSV and a MAT archive. Raw files are unchanged.

Use Lab5_Frequency_Response.png and the run time/spectrum figures for the report.
Check that each fit follows the measured dots. Explain departures from theory.
The harmonic sine fit uses the measured drive frequency; output phase alone
does not measure input/output phase without a synchronized input record.
Hann spectra are frequency cross-checks; use the sine-fit amplitude for X/Y.

MIE402_PreLab5.m is a separate teaching simulation; its values are illustrative.
Lab 4 spring calibration remains a separate package on the Lab 4 page.

Base MATLAB R2020a+ is required for exportgraphics; analysis uses no toolboxes.
If headers are unclear or there are several runs, specify columns explicitly.
An error about time resets or missing samples means the export needs inspection.
No code fills missing observations or changes the original measurements.
