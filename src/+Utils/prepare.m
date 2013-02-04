function [ c, m ] = perform(varargin)
  %% Configure the test case.
  %
  c = Test.configure(varargin{:});

  %% Measure temperature profiles.
  %
  filename = c.stamp('measurement.mat');
  if File.exist(filename)
    c.printf('Measurement: loading cashed data in "%s"...\n', filename);
    load(filename);
  else
    m = Utils.measure(c);
    save(filename, 'm', '-v7.3');
  end
end
