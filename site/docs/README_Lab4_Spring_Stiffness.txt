Lab 4 - Spring stiffness analysis (vertical hanging-spring test)

START
1. Download and unzip the Spring stiffness package into a writable folder.
   Keep all .m files in this folder.
2. In MATLAB open Run_Lab4_Spring_Stiffness.m and click Run, or type:
       Run_Lab4_Spring_Stiffness
   No input arguments are needed. Do not run a helper function.
3. File analysis: choose the force-data file when prompted. Results are saved
   in a new folder beside the first file. For manual B, results use the MATLAB
   current folder. The path is printed at the end.
4. Enter the number of records (normally four), and label the springs A-D.

FOR EACH SPRING, CHOOSE ONE ROUTE
Route 1: Enter the total hanging mass and the fitted Vernier B.
- Include the hanger and every attachment that moves with the hanging mass.
- Select g or kg. If you enter actual weight force, select N; mass = weight/9.81.
- For Force = A*sin(B*t + phase) + offset, B is rad/s.
- If the displayed equation is A*sin(2*pi*f*t + phase), enter f and select Hz.
- Enter measured alpha only if you have a defensible decay-rate estimate.
  Otherwise leave it at 0 and report the light-damping approximation k=m*B^2.
- Save the Vernier fit screenshot. This route cannot generate a measured
  waveform from B alone, and does not pretend to verify the original fit.

Route 2: Import the original Force-versus-Time file.
- Export ONE hanging-spring run from Graphical Analysis as CSV (preferred).
  Excel .xlsx/.xls/.xlsm workbooks are also supported. For multiple sheets,
  select the sheet containing the force-time record when prompted.
  Text titles and unit rows are supported; numerical text is converted.
- Do not use a cart Position CSV here. Verify the suggested Time and Force
  columns (or enter their listed numbers) and choose the units used in the file.
  Start/end times must use the same time units shown in the original file.
- Inspect the displayed raw plot. Enter the start and end times of clean
  vertical free motion AFTER release. Exclude hand contact and impacts.
- Use several clear cycles, preferably at least 15-20 samples/cycle.
- Choose ordinary sine for a short, weakly decaying interval, or damped sine
  when the envelope decays. Default: damped sine.
- Optional search band is in Hz, e.g. [0.5 3]; these are NOT default values
  for your apparatus. Use the observed period to choose a defensible band.
- Check that the fitted curve follows the data and residuals have no clear
  oscillation or drift. A high R2 alone does not validate the physical model.

OUTPUTS
Spring_Stiffness_Summary.csv: one row per record, including mass [kg],
B [rad/s], f [Hz], alpha [1/s], k_light [N/m] and k_used [N/m].
For imported records: SpringID_Force_Fit.png/.fig (measured data + fit,
residuals and annotated k), plus SpringID_Fit_Data.csv.
Manual-B rows have no R2 or residual because raw data were not fitted.
Choose distinct labels such as A_repeat2 for repeated records.
Keep raw data and the output folder; do not overwrite raw files.

PHYSICS
B is the damped angular frequency, f=B/(2*pi).
Light damping: k_light = m_h*B^2.
Damped-sine model: k_used = m_h*(B^2+alpha^2).
Fit model: F(t)=F0+exp(-alpha*t)*(C*cos(B*t)+D*sin(B*t)).
F0,C,D are in N, alpha is in 1/s, and t is time from the selected fit start.
For zero alpha the two stiffness values are equal. Spring mass is neglected;
if appreciable, discuss effective moving mass with the GTA before analysis.
Only clean small-amplitude vertical motion is represented by this model.
The program rejects flat records, invalid timestamps, large time gaps,
poor fits (R2<0.70) and fits with fewer than three cycles. Passing these
checks does not guarantee a good experiment: inspect the plotted evidence.
An entered alpha is not the sine fit's phase parameter.

NEXT: CART ANALYSIS IS A DIFFERENT PROGRAM
Use each measured spring k as the left/right stiffness input to
MIE402_Lab4_Analyze_Free_Response.m. That existing script analyzes the cart;
the spring analysis gives the individual k values. Do not enter the sum twice.

Optional reproducible use (no dialogs)
c=struct('mode','manual','label','A','massValue',200,'massUnit','g', ...
         'B',7.30,'frequencyUnit','rad/s','alpha',0);
r=Lab4_Spring_Stiffness_Analysis(c);  % example only: k=10.658 N/m
For a file also set mode='file', file, sheet (for multi-sheet Excel),
timeColumn, forceColumn, timeScale (to seconds), forceScale (to N), startTime,
endTime, damped=true/false, outputDir and makePlots=true.
Frequency fitting uses base MATLAB operations (no fitting toolbox).
