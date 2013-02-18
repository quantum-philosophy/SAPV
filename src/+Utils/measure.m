function m = measure(c)
  filename = sprintf('%03d_measurement_%s.mat', c.system.processorCount, ...
    DataHash({ c.observations.dieCount, c.observations.timeCount, ...
      c.observations.deviation, c.observations.fixedRNG }));
  [ m, ~ ] = Utils.cache(filename, @perform, c);
end

function m = perform(c)
  %
  % Generate the z's and noise with a fixed RNG.
  %
  if ~isnan(c.observations.fixedRNG)
    rng(c.observations.fixedRNG, 'twister');
  end

  [ m.u, m.n, m.z ] = c.process.sample;

  noise = c.observations.deviation * randn( ...
    c.system.processorCount, c.observations.timeCount, ...
    c.observations.dieCount);

  if ~isnan(c.observations.fixedRNG)
    rng('shuffle', 'twister');
  end

  %
  % Generate temperature profiles for all the dies.
  %
  model = Utils.forward(c, 'model', 'complete');
  m.T = reshape(model.compute(m.u(:)), [ c.system.processorCount, ...
    c.power.stepCount, c.system.wafer.dieCount ]);

  %
  % Thin the data and add the noise.
  %
  m.Tmeas = m.T(:, c.observations.timeIndex, c.observations.dieIndex) + noise;
end
