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

    tic;
    [ T, L ] = mc.compute(c.Pdyn, ...
      'Lnom', c.Lnom, 'Ldev', c.Ldev, ...
      'leakage', c.leakage, 'process', c.process);
    time = toc;

    save(filename, 'L', 'T', 'time', '-v7.3');
  end

  fprintf('Monte Carlo: simulation time %.2f s.\n', time);

  m.T = T;
  m.L = L;

  %
  % Choose spatial locations.
  %
  m.spaceMeasurementIndex = randperm(c.wafer.dieCount);
  m.spaceMeasurementIndex = ...
    sort(m.spaceMeasurementIndex(1:c.spaceMeasurementCount));

  %
  % Choose temporal locations.
  %
  m.timeMeasurementIndex = randperm(c.powerStepCount);
  m.timeMeasurementIndex = ...
    sort(m.timeMeasurementIndex(1:c.timeMeasurementCount));

  %
  % Thin the thermal data.
  %
  m.Tmeas = m.T(:, m.timeMeasurementIndex, m.spaceMeasurementIndex);

  %
  % Add the noise.
  %
  m.Tmeas = m.Tmeas + normrnd(0, c.noiseVariance, size(m.Tmeas));
end
