% MIE 402 Lab 2: quick checks for the course copy of sineFit.m.
% Run from the folder containing sineFit.m:  test_sineFit
t = (0:0.01:8).';
fTrue = 0.75;
y = 0.12 + 0.4*sin(2*pi*fTrue*t + 0.3);

% This mixed row/column call failed in the previous course copy.
p = sineFit(t, y.', 0);
assert(isscalar(p(3)) && abs(p(3)-fTrue) < 0.01, ...
    'Mixed-orientation sinusoid: frequency is not 0.75 Hz.');
assert(abs(p(1)-0.12) < 0.02 && abs(p(2)-0.4) < 0.02, ...
    'Mixed-orientation sinusoid: offset or amplitude is wrong.');

% The same physical signal with the two inputs as columns.
pColumn = sineFit(t, y, 0);
assert(abs(pColumn(3)-p(3)) < 1e-6, ...
    'Row and column input orientations should give the same frequency.');

fprintf('sineFit checks passed: frequency %.4f Hz (expected %.4f Hz).\n', ...
    p(3), fTrue);
