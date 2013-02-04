clear all;
close all;
setup;

[ c, m ] = Utils.prepare;

c.inference.proposalRate = 0.20;
c.inference.optimizationStepCount = 1e4;

results{1} = Utils.perform(c, m);

c.inference.proposalRate = 0.05;
c.inference.optimizationStepCount = NaN;

results{2} = Utils.perform(c, m);

names = { 'Optimized', 'Not optimized' };
count = length(names);

%% Header.
%
fprintf('%10s', '');
for i = 1:count
  fprintf(' %15s', names{i});
end
fprintf('\n');

%% Timing.
%
fprintf('%10s', 'Time, m');
for i = 1:count
  fprintf(' %15.2f', results{i}.time / 60);
end
fprintf('\n');

%% Accuracy.
%
fprintf('%10s', 'NRMSE, %');
for i = 1:count
  fprintf(' %15.2f', results{i}.error * 100);
end
fprintf('\n');
