# Lab 6 reversal check

Use this optional Python check **at home**, after opening the original recording and finding a suspected pause and change of direction. The MATLAB bundle remains the standard workflow for passage marks and RPM.

1. In the original, normal-speed phone movie, note the file times of lamp OFF and of the suspected turn. Use the same clock for both. Pick a rectangle centered on **one** rotor hub, with visible vane detail on both sides. Record the top-left pixel and rectangle width and height in the decoded, upright image. Review each bulb separately.
2. With Python installed, install NumPy, SciPy and OpenCV using `python -m pip install numpy scipy opencv-python`. Download `Lab6_Check_Reversal.py` and run it next to your original recording. Replace these example values with yours.

   ```text
   python Lab6_Check_Reversal.py A_phone_off.mov --guess 24 --light-off 5 --roi 310 350 160 116
   ```

3. Check the original frames before, at and after the candidate. Confirm the vane moves backward relative to its illuminated direction and a fixed glass or base detail. Distinguish sustained reverse rotation from brief recoil. If the two sides disagree, the glass shifts, a reflection crosses the crop, the vane disappears, or the clip ends too soon, record **unclear**. Keep the file name and frame or timestamp evidence. Use MATLAB and verified same-direction passages for speeds.

The check measures a local extremum in vane appearance on each side, using the same image-feature and pose-turn approach as the pilot. The original pilot used clip-specific fixed-glass registration. This adaptation assumes a stationary camera and adequate light, with both sides of the rotor continuously visible. It can help check a suspected turn and does not infer a reversal from periodicity alone. A candidate time is not a direction label or a confidence interval.

Prefer the continuous phone recording for time since OFF. A constant-rate Chronos clip that contains OFF can use `--capture-fps` with its actual acquisition rate. For a late clip without OFF, use the recorded start delay plus the physical frame time instead. If the movie is slow motion, do not use its playback timestamps as real time.

## Original pilot source

The [original analysis code](Lab6_Pilot_Reversal_Source.zip) is provided for reference. Its calibration and input files are specific to the pilot. The optional check above is the version for your own recording.
