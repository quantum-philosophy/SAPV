function m = measure(c)
  m = Options;

  %
  % Generate temperature profiles for all the dies.
  %
  model = Utils.forward(c, 'model', 'complete');

  [ m.u, m.n, m.z ] = c.process.sample;

  m.T = reshape(model.compute(m.u(:)), [ c.system.processorCount, ...
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
