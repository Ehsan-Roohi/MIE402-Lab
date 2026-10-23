MIE 402 LAB 3 — RING-SHAPED BOB VIDEO TRACKING

Use Run_Lab3_Ring_Video_Tracker.m to extract the centers of two bright,
ring-shaped bobs from an existing video against a dark background.
If you already have valid tracked positions in ExpData.mat, run
Run_Lab3_ExpData_Analysis.m directly instead.

REQUIREMENTS
MATLAB with Image Processing Toolbox, or GNU Octave with the image and
video packages. In Octave, load both packages before running:
  pkg load image
  pkg load video
No curve-fitting or signal-processing toolbox is needed by this tracker.

RUN
1. Extract the download into a writable folder. Open the .m file and run
   Run_Lab3_Ring_Video_Tracker with no arguments, then choose the original
   MP4. Run the main function, not its local helper functions.
2. Follow the prompts to click, in order:
   - The center of the FIXED pivot.
   - The center of the UPPER moving joint/bob (bob 1).
   - The center of the LOWER moving bob (bob 2).
   - The inner edge of bob 1's dark central hole.
   - The inner edge of bob 2's dark central hole.
   The last two clicks measure the HOLE radii, not the outer ring radii.
3. Enter the actual CAMERA CAPTURE frame rate and the measured distance
   from the fixed pivot center to the upper moving joint center, in mm.
   Lab 3 specifies nominal 1000 capture frames/s; use your actual setting
   if different. Do not enter the slow-motion MP4 playback rate instead.
   Leave unavailable inputs blank: the output will remain pixels/frame.
4. Let the code process the recording. It searches near the previous
   centers, checks both link lengths and ring sizes, and retries a full
   image search if the local match is missing or ambiguous. A single
   candidate cannot be assigned to both bobs in the same frame.
5. Inspect the length and angle plots against the original recording,
   particularly when the bobs cross, overlap, or a hand obscures them.
   Geometry checks alone do not prove that every detection is correct.
6. With physical timing and calibration supplied, open the saved
   RingTracking_ExpData.mat in Run_Lab3_ExpData_Analysis.m for angular
   velocity and frequency plots. Otherwise obtain the missing settings
   before interpreting frequencies or distances in physical units.

OUTPUT: <video name>_RingTracking
- TrackingPixels.mat: raw centers, measured pixel lengths, wrapped angles,
  initialization/configuration, accepted-detection and continuity flags.
- tracking_pixels.csv: the same numeric measurements and quality flags.
- tracking_check.png and .fig: measured lengths and wrapped link angles.
- RingTracking_ExpData.mat: generated only with a positive capture rate
  and physical calibration length. ExpData columns are:
  time_s, x1_mm, y1_mm, x2_mm, y2_mm.
  Positions are relative to the fixed pivot, with x right and y up.

QUALITY AND LIMITATIONS
No missing or ambiguous positions are interpolated by this tracker.
Unresolved frames remain NaN. Raw detections are retained, while flagged
large frame-to-frame jumps are excluded from the physical ExpData output.
A flag can indicate poor tracking, a cut/buffer boundary, or rapid motion;
review the video rather than assuming which explanation is correct.
Measured link lengths are NOT forced to constant values.

Angles are absolute link angles from the downward vertical, positive
toward image-right. Each angle lies in [-pi,pi] radians ([-180,180] deg)
in this output. A jump at that angle boundary is not itself a tracking
failure. Continuous rotation is handled by the separate analysis file.

Keep the camera and fixed pivot stationary. This method needs enclosed,
visible dark holes within bright rings. Other bob shapes, severe
occlusion, or substantial out-of-plane motion need separate review.
Do not fill long missing segments simply to obtain a continuous curve.

OPTIONAL BATCH/PREVIEW SETTINGS
  cfg.pivotPx = [x y];                 % MATLAB 1-based pixel centers
  cfg.initialCentersPx = [x1 y1; x2 y2];
  cfg.innerRadiiPx = [r1 r2];
  cfg.captureFps = 1000;               % replace with actual capture rate
  cfg.upperLengthMm = 167;            % EXAMPLE ONLY: use your measurement
  cfg.maxFrames = 100;                % preview; omit to process to end
  cfg.makeFigures = false;            % optional noninteractive batch run
  R = Run_Lab3_Ring_Video_Tracker('recording.mp4',cfg);
For a later segment, cfg.startFrame is a zero-based original frame index;
initialize the two centers from that segment's first frame. Saved frame
numbers and physical timestamps retain this original-frame offset.
