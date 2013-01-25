function m = measure(c)
  m = Options;

  %
  % Generate temperature profiles for all the dies.
  %
  model = Utils.forward(c, 'model', 'complete');

  m.Z = randn(c.process.model.dimensionCount, 1);

  U = c.process.model.mapping * m.Z;
  m.U = reshape(U, [ c.system.processorCount, c.system.wafer.dieCount ]);

  T = model.compute(m.Z);
  m.T = reshape(T, [ c.system.processorCount, ...
    c.power.stepCount, c.system.wafer.dieCount ]);

  %
  % Thin the data.
  %
  Tmeas = m.T(:, c.observations.timeIndex, c.observations.dieIndex);

  %
  % Add some noise.
  %
  m.Tmeas = Tmeas + c.observations.noiseDeviation * randn( ...
    c.system.processorCount, c.observations.timeCount, c.observations.dieCount);
end
