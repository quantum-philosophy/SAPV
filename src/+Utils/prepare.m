function [ c, m ] = perform(varargin)
  %% Configure the test case.
  %
  c = Test.configure(varargin{:});

  plot(c.system.wafer, c.observations.dieIndex);

  %% Measure temperature profiles.
  %
  filename = c.stamp('measurement.mat');
  if File.exist(filename)
    c.printf('Measurement: loading cashed data in "%s"...\n', filename);
    load(filename);
  else
    time = tic;
    m = Utils.measure(c);
    time = toc(time);

    save(filename, 'time', 'm', '-v7.3');
  end

  m.time = time;

  c.printf('Measurement: done in %.2f minutes.\n', time / 60);
end
