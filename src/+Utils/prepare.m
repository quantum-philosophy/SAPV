function [ c, m ] = perform(varargin)
  %% Configure the test case.
  %
  c = Test.configure(varargin{:});

  %% Measure temperature profiles.
  %
  if ~isnan(c.observations.fixedRNG)
    filename = sprintf('measurement_%03d_%03d.mat', ...
      c.system.processorCount, c.observations.fixedRNG);
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
