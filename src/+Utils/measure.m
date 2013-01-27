function m = measure(c)
  m = Options;

  %
  % Generate temperature profiles for all the dies.
  %
  model = Utils.forward(c, 'model', 'complete');

  [ u, n, m.z ] = c.process.sample;
  m.n = reshape(n, [ c.system.processorCount, c.system.wafer.dieCount ]);
  m.u = reshape(u, [ c.system.processorCount, c.system.wafer.dieCount ]);

  T = model.compute(m.z);
  m.T = reshape(T, [ c.system.processorCount, ...
    c.power.stepCount, c.system.wafer.dieCount ]);

  %
  % Thin the data.
  %
  Tmeas = m.T(:, c.observations.timeIndex, c.observations.dieIndex);

  %
  % Add some noise.
  %
  m.Tmeas = Tmeas + c.observations.deviation * randn( ...
    c.system.processorCount, c.observations.timeCount, c.observations.dieCount);
end
