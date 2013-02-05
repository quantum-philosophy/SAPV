clear all;
setup;

[ c, m ] = Utils.prepare;

c.inference.optimizationMethod = 'none';
c.inference.proposalRate = 0.05;
results{1} = Utils.perform(c, m);

c.inference.optimizationMethod = 'fminunc';
c.inference.proposalRate = 0.20;
results{2} = Utils.perform(c, m);

c.inference.optimizationMethod = 'csminwel';
c.inference.proposalRate = 0.20;
results{3} = Utils.perform(c, m);

names = { 'none', 'fminunc', 'csminwel' };
count = length(names);

%% Header.
%
fprintf('%15s', 'Optimization');
for i = 1:count
  fprintf(' %15s', names{i});
end
fprintf('\n');

%% Timing.
%
fprintf('%15s', 'Time, m');
for i = 1:count
  fprintf(' %15.2f', results{i}.time / 60);
end
fprintf('\n');

%% Accuracy.
%
fprintf('%15s', 'NRMSE, %');
for i = 1:count
  fprintf(' %15.2f', results{i}.error * 100);
end
fprintf('\n');
