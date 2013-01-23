function m = measure(c)
  m = Options;

  %
  % Generate temperature profiles for all the dies.
  %
  hs = HotSpot.Batch('floorplan', c.system.floorplan, ...
    'config', c.temperature.configuration, 'line', c.temperature.line);

  m.U = c.process.Unom + c.process.Udev * c.process.model.sample;
  T = hs.compute(c.power.Pdyn, ...
    'leakage', c.leakage.model, 'parameters', m.U(:));
  m.T = reshape(T, [ c.system.processorCount, ...
    c.power.stepCount, c.system.wafer.dieCount ]);

  %
  % Choose spatial locations.
  %
  spaceMeasurementIndex = randperm(c.system.wafer.dieCount);
  m.spaceMeasurementIndex = ...
    sort(spaceMeasurementIndex(1:c.observations.spaceStepCount));

  %
  % Choose temporal locations.
  %
  timeMeasurementIndex = randperm(c.power.stepCount);
  m.timeMeasurementIndex = ...
    sort(timeMeasurementIndex(1:c.observations.timeStepCount));

  %
  % Generate some noise.
  %
  noise = c.observations.noiseDeviation * ...
    randn(c.system.processorCount, c.observations.timeStepCount, ...
      c.observations.spaceStepCount);

  %
  % Thin the data.
  %
  m.Tmeas = m.T(:, m.timeMeasurementIndex, m.spaceMeasurementIndex);

  %
  % Add the noise.
  %
  m.Tmeas = m.Tmeas + noise;
end
