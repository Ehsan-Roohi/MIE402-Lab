testRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(testRoot,'site','docs'));
R=Lab6_Passage_Speed((0:250:2000)',1000,4);
assert(abs(R.mean_rpm-60)<1e-10);
assert(max(abs(R.interval_rpm-60))<1e-10);
assert(~any(R.review));
R2=Lab6_Passage_Speed((1:250:2001)',1000,4);
assert(abs(R2.mean_rpm-R.mean_rpm)<1e-10);
R3=Lab6_Passage_Speed([0 250 500 1000 1250]',1000,4);
assert(any(R3.review));
assert(R3.interval_rpm(3)==30); % missed crossing remains visible
failed=false; try, Lab6_Passage_Speed([0 1 1],1000,4); catch, failed=true; end
assert(failed);
failed=false; try, Lab6_Passage_Speed([0 NaN 2],1000,4); catch, failed=true; end
assert(failed);
failed=false; try, Lab6_Passage_Speed([0 1 2],0,4); catch, failed=true; end
assert(failed);
disp('Lab 6 passage-speed regression checks passed.');
