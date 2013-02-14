function [ c, m ] = perform(varargin)
  %% Configure the test case.
  %
  c = Test.configure(varargin{:});

  %% Measure temperature profiles.
  %
  if ~isnan(c.observations.fixedRNG)
    filename = sprintf('%03d_measurement_%03d_%03d_%s_%03d.mat', ...
      c.system.processorCount, c.observations.dieCount, ...
      c.observations.timeCount, num2str(c.observations.deviation), ...
      c.observations.fixedRNG);
  else
    filename = c.stamp('measurement.mat');
  end
  if File.exist(filename)
    c.printf('Measurement: loading cached data in "%s"...\n', filename);
    load(filename);
  else
    m = Utils.measure(c);
    save(filename, 'm', '-v7.3');
  end
end
