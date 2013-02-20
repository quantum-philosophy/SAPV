function m = measure(c)
  stamp = Utils.stamp(c, 'measurement', c.system, c.observations);
  [ m, ~ ] = Utils.cache(stamp, @perform, c);
end

function m = perform(c)
  %
  % Generate the z's and noise with a fixed RNG.
  %
  if ~isnan(c.observations.fixedRNG)
    rng(c.observations.fixedRNG, 'twister');
  end

  [ m.u, ~, m.z ] = c.process.sample;

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
  m.T = model.compute(m.u(:));

  %
  % Thin the data and add the noise.
  %
  m.Tmeas = m.T(:, c.observations.timeIndex, c.observations.dieIndex) + noise;
end
