OPTIONAL LAB 6 MOLECULAR MONTE CARLO
Unzip both .m files into one folder. Open Run_Lab6_Molecular_MC.m and click Run.
Base MATLAB is sufficient. The script exports three figures and one CSV.

What it teaches
Sample flux-weighted normal molecular velocities, calculate momentum change,
and compare a Monte Carlo pressure difference with its analytical expectation.
The incoming gas reservoirs have the same pressure and temperature. Surface
temperatures, nitrogen molecular mass and diffuse-reflection fraction are
illustrative inputs, not measurements of the sealed classroom radiometer.

The model assumes independent free-molecular reservoirs on the two faces.
It excludes gas-gas collisions, finite-vane edges, confinement, heat transfer
and rotor motion. It is NOT full DSMC and does not predict the bulb's rpm or
its unknown Knudsen number. Optical black/shiny appearance does not determine
the molecular diffuse-reflection probability.

Try: equal wall temperatures; hot/cold temperature reversal; larger sample
counts; diffuse fraction 0, 0.5 and 1. Explain why finite samples fluctuate
about the analytical value. At diffuse fraction zero this paired estimator
gives zero thermal force. At zero reservoir pressure the dimensional force
vanishes; the plotted ratio deltaP/p is a limiting normalization, not a force
at p=0. Do not extrapolate this collisionless model to atmospheric pressure.

Reference expectation:
deltaP/p = diffuseFraction/2 * (sqrt(Thot/Tgas)-sqrt(Tcold/Tgas)).
Velocity samples follow the wall-crossing distribution, not the ordinary
bulk normal Gaussian. This is the gas-surface step used in kinetic methods.
For full rarefied-flow context: Baier, Hardt, Shahabi & Roohi (2017),
https://doi.org/10.1103/PhysRevFluids.2.033401 ; Lotfian & Roohi (2018),
https://doi.org/10.1017/jfm.2018.880 . These are research examples, not
validation of this classroom wall model against the sealed rotor.
