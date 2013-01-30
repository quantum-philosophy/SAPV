clear all;
close all;
setup;

fprintf('%15s %15s %15s %15s\n', 'PEs per die', 'PEs per wafer', ...
  'Variables', 'Time, s');

for processorCount = [ 2 4 8 16 32 ]
  time = tic;
  c = Test.configure(processorCount);
  fprintf('%15d %15d %15d %15.2f\n', processorCount, ...
    processorCount * c.system.wafer.dieCount, ...
    c.process.dimensionCount, toc(time));
end