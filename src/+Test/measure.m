function m = generate(c)
  m = Options;

  %
  % Generate temperature profiles for all the dies.
  %
  filename = File.temporal(sprintf('MonteCarlo_%s.mat', ...
    DataHash({ c.power.Pdyn, Utils.toString(c.leakage.model), ...
      Utils.toString(c.process.model) })));

  if File.exist(filename)
    fprintf('Monte Carlo: using cached data in "%s"...\n', filename);
    load(filename);
  else
    fprintf('Monte Carlo: simulation...\n');

    mc = HotSpot.MonteCarlo('floorplan', c.system.floorplan, ...
      'config', c.temperature.configuration, 'line', c.temperature.line);

    time = tic;
    [ T, L ] = mc.compute(c.power.Pdyn, ...
      'Lnom', c.process.Lnom, 'Ldev', c.process.Ldev, ...
      'leakage', c.leakage.model, 'process', c.process.model);
    time = toc(time);

    %
    % Choose spatial locations.
    %
    spaceMeasurementIndex = randperm(c.system.wafer.dieCount);
    spaceMeasurementIndex = ...
      sort(spaceMeasurementIndex(1:c.observations.spaceStepCount));

    %
    % Choose temporal locations.
    %
    timeMeasurementIndex = randperm(c.power.stepCount);
    timeMeasurementIndex = ...
      sort(timeMeasurementIndex(1:c.observations.timeStepCount));

    %
    % Generate some noise.
    %
    noise = c.observations.noiseDeviation * ...
      randn(c.system.processorCount, c.observations.timeStepCount, ...
        c.observations.spaceStepCount);

    save(filename, 'L', 'T', 'time', 'spaceMeasurementIndex', ...
      'timeMeasurementIndex', 'noise', '-v7.3');
  end

  fprintf('Monte Carlo: done in %.2f seconds.\n', time);

  m.T = T;
  m.L = L;

  m.spaceMeasurementIndex = spaceMeasurementIndex;
  m.timeMeasurementIndex = timeMeasurementIndex;

  %
  % Thin the data.
  %
  m.Tmeas = m.T(:, m.timeMeasurementIndex, m.spaceMeasurementIndex);

  %
  % Add the noise.
  %
  m.Tmeas = m.Tmeas + noise;
end
