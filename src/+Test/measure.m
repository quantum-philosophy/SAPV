function m = generate(c)
  %
  % Generate temperature profiles for all the dies.
  %
  filename = File.temporal(sprintf('MonteCarlo_%s.mat', ...
    DataHash({ c.Pdyn, Utils.toString(c.leakage), ...
      Utils.toString(c.process) })));

  if File.exist(filename)
    fprintf('Monte Carlo: using cached data in "%s"...\n', filename);
    load(filename);
  else
    fprintf('Monte Carlo: simulation...\n');

    mc = HotSpot.MonteCarlo('floorplan', c.floorplan, ...
      'config', c.hotspotConfig, 'line', c.hotspotLine);

    time = tic;
    [ T, L ] = mc.compute(c.Pdyn, ...
      'Lnom', c.Lnom, 'Ldev', c.Ldev, ...
      'leakage', c.leakage, 'process', c.process);
    time = toc(time);

    %
    % Choose spatial locations.
    %
    spaceMeasurementIndex = randperm(c.wafer.dieCount);
    spaceMeasurementIndex = ...
      sort(spaceMeasurementIndex(1:c.spaceMeasurementCount));

    %
    % Choose temporal locations.
    %
    timeMeasurementIndex = randperm(c.powerStepCount);
    timeMeasurementIndex = ...
      sort(timeMeasurementIndex(1:c.timeMeasurementCount));

    %
    % Generate some noise.
    %
    noise = sqrt(c.noiseVariance) * randn(c.processorCount, ...
      c.timeMeasurementCount, c.spaceMeasurementCount);

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
