function m = measure(c)
  model = Utils.forward(c, 'model', 'complete');

  %
  % Fix the random number generator?
  %
  if ~isnan(c.observations.fixedRNG)
    rng(c.observations.fixedRNG, 'twister');
  end

  m = Options;

  %
  % Generate the main quantities.
  %
  [ m.u, m.n, m.z ] = c.process.sample;

  %
  % Generate temperature profiles for all the dies.
  %
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

  %
  % NOTE: But the rest of the inference should not be fixed.
  %
  if ~isnan(c.observations.fixedRNG)
    rng('shuffle', 'twister');
  end
end
