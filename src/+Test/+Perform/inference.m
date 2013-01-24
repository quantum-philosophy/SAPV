clear all;
close all;
setup;

if File.exist('rng.mat')
  load('rng.mat');
else
  r = rng;
  save('rng.mat', 'r', '-v7.3');
end

rng(r);

%% Configure the test case.
%
c = Test.configure;

%% Measure temperature profiles.
%
m = Test.measure(c);

%% Construct the surrogate model.
%
Test.infer(c, m);
