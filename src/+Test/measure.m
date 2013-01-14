function m = generate(c)
  %
  % Generate temperature profiles for all the dies.
  %
  mc = HotSpot.MonteCarlo('floorplan', c.floorplan, ...
    'config', c.hotspotConfig, 'line', c.hotspotLine);
  [ m.T, m.L ] = mc.compute(c.Pdyn, 'leakage', c.leakage, ...
    'process', c.process, 'verbose', true);

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
  m.Tmeas = m.T(m.spaceMeasurementIndex, :, m.timeMeasurementIndex);

  %
  % Add the noise.
  %
  m.Tmeas = m.Tmeas + normrnd(0, c.noiseVariance, size(m.Tmeas));
end
