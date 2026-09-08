# Lecture 01 · Orientation and report writing

MIE 402 · Fall 2026 · September 9 · 50 minutes

[PowerPoint](site/docs/MIE402_Lecture01_Report_Writing_Fall2026_v1.pptx) · [PDF](site/docs/MIE402_Lecture01_Report_Writing_Fall2026_v1.pdf) · [Report template](site/docs/MIE402_Report_Template.docx)

## 01. Course orientation and laboratory reports

**MIE 402.** Mechanical Engineering Laboratory II

**Fall 2026.** Prof. Ehsan Roohi · September 9, 2026

## 02. Experimental evidence and engineering judgment

**Observe and measure.** Identify the behavior, then record it with a documented measurement system.

**Compare and communicate.** Test the model against data and explain what the evidence supports.

## 03. Today’s 50-minute session

**0–8 min.** Course organization and the laboratory workflow

**8–23 min.** Six experiments, apparatus, measurements, and analysis

**23–42 min.** Report structure, figures, comparison, and uncertainty

**42–48 min.** Policies and a short report exercise

**48–50 min.** First dates and preparation

## 04. People, places, and weekly rhythm

**Instructor.** Prof. Ehsan Roohi · roohie@umass.edu · Gunness Laboratory, Room 1

**Graduate teaching assistants.** Yuyuan Zhang and Nazila Emamdoost

**Theory.** Monday, 12:20–1:10 PM · Hasbrouck Laboratory 134

**Laboratory / office hours.** Lab sections: Tuesday–Friday, Gunness Laboratory 5. Office hours: Friday, 12:20–1:10 PM, Gunness Laboratory 1.

## 05. Course grading

| Component | Weight |
| --- | --- |
| Six pre-labs, equally weighted | 20% |
| Lab 1 report | 10% |
| Combined Labs 2 and 3 report | 25% |
| Combined Labs 4 and 5 report | 25% |
| Lab 6 report | 15% |
| Participation | 5% |

## 06. The laboratory workflow

**Before the section.** Read the procedure, prepare the model, and submit the pre-lab.

**During the section.** Save raw data, settings, initial conditions, and observations.

**After the section.** Process the data, compare with theory, and explain the result.

## 07. Six experiments and four reports

| Lab | Experiment | Report |
| --- | --- | --- |
| 1 | Dynamic data sampling and frequency analysis | Lab 1 |
| 2 | Single pendulum | Labs 2 + 3 |
| 3 | Double pendulum | Labs 2 + 3 |
| 4 | 1-DOF system: free response | Labs 4 + 5 |
| 5 | 1-DOF system: forced response | Labs 4 + 5 |
| 6 | Radiometer | Lab 6 |

## 08. Lab 1: Sampling and frequency analysis

**Apparatus.** Moku:Go data logger, microphone, speaker, and sound sources such as a tuning fork.

**Data collection.** Record at least one second at several rates relative to the source frequency, then replay and save each data file.

**Analysis.** Compare time histories and FFT spectra. Identify the fundamental frequency, aliasing, and the effect of record length.

**Report focus.** Explain why sampling rate controls representation while record duration controls frequency resolution.

fₛ > 2 fmax      Δf = fₛ / N = 1 / Trecord

*The procedure includes rates such as 100f, 10f, 3f, 1.4f, and 1f. Record the actual settings for every run.*

## 09. Lab 2: Single pendulum

**Apparatus.** Single pendulum, high-speed camera at the assigned frame rate, scale reference, and the MATLAB tracking app.

**Data collection.** Release from rest at small, medium, and large initial angles. Record the angle, geometry, masses, and video settings.

**Analysis.** Convert tracked coordinates to angle and angular velocity. Compare time histories, spectra, period, and numerical prediction.

**Report focus.** Explain when the small-angle model works and how inertia, damping, calibration, and release angle affect agreement.

Iₚ θ̈ + m g d sin θ = 0      Tsmall = 2π √(Iₚ / m g d)

*The procedure uses releases below 10°, from 10° to 90°, and from 90° to 180°. Match simulation and experiment initial conditions.*

## 10. Lab 3: Double pendulum

**Apparatus.** Two-link pendulum, high-speed camera, scale reference, and image tracking for both moving masses.

**Data collection.** Record a small-angle release and at least three large-angle cases. Save both initial angles and release conditions.

**Analysis.** Compute both angles and angular velocities, then compare time histories and spectra with the coupled numerical model.

**Report focus.** Discuss coupling, sensitivity to initial conditions, tracking error, and where measured and simulated trajectories begin to diverge.

*A complicated or diverging trajectory alone does not establish chaos. First verify initial conditions, time alignment, and tracking.*

## 11. Lab 4: Free response of a 1-DOF system

**Apparatus.** Vernier cart and position sensor, force sensor, springs, added masses, and eddy-current dampers.

**Data collection.** Measure mass and spring stiffness. Displace the cart, release it, and repeat with changed mass, stiffness, and damping.

**Analysis.** Use displacement histories, peak decay, and spectra to estimate damped frequency, natural frequency, and damping ratio.

**Report focus.** Relate each controlled change to the model and document effective stiffness, initial displacement, sampling rate, and peak selection.

m ẍ + c ẋ + k x = 0      ωn = √(k / m)      ζ = c / (2√(k m))

*The procedure uses a base case plus variations in mass, springs, and dampers. Verify each exported CSV before leaving.*

## 12. Lab 5: Forced response of a 1-DOF system

**Apparatus.** Vernier cart, springs, motor-driven input, magnetic dampers, tachometer, and Graphical Analysis software.

**Data collection.** Record three impulse cases, then harmonic steady-state responses below and above resonance while avoiding prolonged resonance.

**Analysis.** Separate transient and steady motion. Compute output-to-input magnitude and compare the experimental Bode plot with the model.

**Report focus.** Use measured input amplitude and frequency for every point. Connect Lab 4 parameter estimates to the forced-response prediction.

m ẍ + c ẋ + k x = F(t)

*Let the response settle before measuring amplitude. Convert tachometer RPM to rad/s and document any configuration changes.*

## 13. Lab 6: Radiometer rotation

**Apparatus.** Crookes radiometer, LED light, lux meter, fixed camera, matte black background, ruler, and optional IR thermometer.

**Data collection.** Record a clear 60–90 s video at a close safe light distance. Keep geometry fixed and note lux and thermal history.

**Analysis.** Track the vane within an annulus, unwrap cumulative angle, fit its slope for average RPM, and inspect interval RPM for slowdown.

**Report focus.** Connect rotation to rarefied-gas thermal transport. Explain why lux is an imperfect heat-input measure and why warming matters.

θ(t) ≈ θ₀ + ωavg t      RPM = (60 / 2π) ωavg

*A practical start is about 15 cm from the light with the background 20–30 cm behind the bulb. Follow the released safety limits.*

## 14. The structure of a laboratory report

**Required sections.** Abstract, Introduction, Method, Results, Comparison, Discussion, Conclusions, and References

**Supporting material.** Appendices are optional. Essential evidence belongs in the main report.

**Reader.** Write for an engineering student who has completed Dynamics and Fluid Mechanics.

## 15. Report length and section purpose

| Section | Template allocation | Main purpose |
| --- | --- | --- |
| Abstract | Maximum 10 lines | Purpose, method, key finding, implication |
| Introduction | 1 page | Theory, experiment, and testable objective |
| Method | 1 page | Enough detail to reproduce the measurement |
| Results | 3 pages including figures | Observed behavior and processed measurements |
| Comparison | 1 page | Prediction and experiment on the same basis |
| Discussion | 1 page | Discrepancies, uncertainty, and limitations |
| Conclusions | 1 page | Quantitative answer and the main lesson |

*References and optional appendices have no stated page limit. Follow any assignment-specific limit on Canvas.*

## 16. Introduction and reproducible method

**Introduction.** State a testable objective. Give the governing equation, define symbols, and explain assumptions.

**Method.** Describe the actual apparatus, calibration, sampling settings, initial conditions, and repeated runs.

**Analysis record.** Explain processing choices, fitting intervals, and parameter sources so another person can repeat the analysis.

*Example objective: test how release angle changes agreement with the small-angle pendulum model.*

## 17. A concise, quantitative abstract

**Purpose and method.** We tested a small-angle pendulum prediction using angle histories from video.

**Key result.** The measured frequency was 1.47 Hz, compared with a predicted 1.50 Hz, a 2.0% difference.

**Meaning and limit.** The agreement supports the model for this case. The discrepancy requires an uncertainty assessment.

*Illustrative wording and invented teaching values. An actual abstract must use your own results. Maximum 10 lines.*

## 18. Results: the measured behavior

**Observation.** Describe what the measurements show, with quantities and units.

**Evidence.** Use figures or tables that answer the experimental question. Identify conditions and repeated runs.

**Traceability.** Distinguish measured data, processed measurements, and simulation predictions.

*Example observation: successive positive displacement peaks decrease over time.*

## 19. Readable, exported figures

**Figure requirements.** Numbered figure, descriptive caption, axis labels with units, legible text, and clear legend.

**Export.** Use high-resolution PNG, EPS, or PDF. Do not use screenshots of MATLAB or Python figure windows.

**Final check.** Inspect the submitted PDF at the size the reader will use.

## 20. A figure that supports a comparison

![Illustrative comparison](site/assets/comparison.svg)

*Figure 1. Illustrative angle histories: undamped model and synthetic decaying signal, 5° initial angle, 50 samples/s.*

## 21. Comparison: a fair test of the model

**Same basis.** Use matching units, initial conditions, time origin, and system parameters. Explain the theoretical solution.

**Quantitative comparison.** Compare period, frequency, amplitude, phase, damping, or another quantity relevant to the objective.

**Parameter honesty.** State which parameters you measured, assumed, or fitted. A fit to the same data is not independent validation.

Relative discrepancy = | measured − predicted | / | predicted | × 100%

*Use an appropriate absolute or scaled metric when the predicted value is zero or very small.*

## 22. Uncertainty and acceptable agreement

**Measurement uncertainty.** Consider calibration, resolution, repeatability, timing, and tracking choices.

**Model uncertainty.** Consider uncertain parameters and omitted physics, such as friction or large-angle effects.

**A justified conclusion.** Report what each uncertainty means. Compare the discrepancy with a consistent uncertainty estimate.

T = Δt / ncycles      uT ≈ uΔt / ncycles

*Simplified timing example with exact cycle count. Longer timing intervals do not remove calibration bias.*

## 23. Discussion: explanations tied to evidence

**Observed difference.** The measured oscillation envelope decays while the undamped prediction keeps constant amplitude.

**Plausible mechanism.** Friction or drag could dissipate energy. The present comparison does not identify their separate contributions.

**Discriminating check.** Compare decay across configurations and test whether the chosen damping model describes the envelope.

*Replace “human error” with a specific mechanism, its expected effect, and a way to check it.*

## 24. Conclusions, references, and appendices

**Conclusions.** Answer the objective with the key numerical result, supported limitation, and a useful improvement.

**References.** Cite sources where used. Include the lecture notes at minimum and list every cited source.

**Appendices.** Add supporting calculations or extra data only when needed. Keep essential evidence in the main text.

## 25. Combined reports connect related experiments

**Labs 2 and 3.** Compare one angle with two coupled angles. Discuss model assumptions, initial conditions, and the limits of prediction.

**Labs 4 and 5.** Relate free-response frequency and damping to the forced response. Account for configuration changes.

**Organization.** Use one abstract and conclusion, with experiment-specific subsections and an explicit synthesis.

*Suggested organization within the required template. Do not assume the page allowance doubles.*

## 26. The report rubric: ten equal criteria

| Each criterion is 10% of the report grade | What to check |
| --- | --- |
| Complete sections / overall aesthetic | Required organization and consistent formatting |
| Clear figures / abstract | Readable evidence and a concise, quantitative summary |
| Data analysis / introducing the theory | Traceable processing and defined governing equations |
| Introducing the experiment / comparison with theory | Physical context and a fair model-data comparison |
| Discussion / meaningful results | Evidence-based interpretation and an answer to the objective |

*This table groups the ten original rubric criteria into pairs. Each individual criterion remains worth 10%.*

## 27. Submission and integrity policies

**Pre-labs.** Due on Canvas before your own section starts. Late pre-labs are not accepted.

**Reports.** Due on Canvas at 11:59 PM. A report grade loses 25% for each day or partial day late.

**Integrity and verification.** Discuss approaches, but do not copy solutions or share MATLAB, Python, or Simulink source files. Be ready to explain your submitted work.

## 28. Three-minute report exercise

**Draft sentence.** “The frequency was 1.47. Theory was 1.50. The error was small because of human error.”

**Work with a neighbor.** Add units, calculate the discrepancy, and separate the observation from its interpretation.

**Then decide.** What information is missing before you can judge agreement? Suggest one check that would help.

*Invented teaching values. No submission is required for this in-class discussion.*

## 29. Exercise debrief

**Results and comparison.** The measured frequency was 1.47 Hz and the predicted frequency was 1.50 Hz. Their difference was 0.03 Hz, or 2.0% of the prediction.

**Discussion.** This discrepancy alone does not establish acceptable agreement. Timing and model-parameter uncertainties are needed.

**Useful next check.** Verify the time calibration and repeat the frequency estimate using a stated interval and method.

*Other specific, evidence-based checks can also be valid.*

## 30. The first dates

**September 9.** One-time Wednesday orientation. No laboratory in Weeks 1–2.

**September 14.** Measurement fundamentals

**September 21–25.** Lab 1 week. Pre-lab 1 is due before your own section.

**October 5.** Lab 1 report due on Canvas at 11:59 PM

## 31. Preparation for Lab 1

**Before Week 3.** Confirm your lab section and GTA. Arrange MATLAB and Simulink access. Read the released Lab 1 and pre-lab instructions.

**Bring to the laboratory.** A way to save and back up your raw data, and a record of your preparation.

**Exit question.** What evidence would you need before trusting a measured frequency?

