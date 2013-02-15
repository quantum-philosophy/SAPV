function results = perform(c, m, sampleCount)
  filename = c.stamp('inference.mat');
  if File.exist(filename);
    c.printf('Inference: loading cached data in "%s"...\n', filename);
    load(filename);
  else
    %% Initialize the forward model.
    %
    model = Utils.forward(c, 'model', 'observed');

    c.printf('Inference: in progress using "%s"...\n', c.inference.sampler);

    %% Do the inference.
    %
    metropolis = MetropolisHastings.(c.inference.sampler)(c, m, model);
    results = metropolis.sample;

    save(filename, 'results', '-v7.3');
  end

  %
  % Here, we introduce a possibility of shrinking the number of
  % samples that we would like to consider.
  %
  if nargin < 3, sampleCount = results.samples.count; end

  assert(sampleCount <= results.samples.count);

  burninCount = round(c.inference.burninRate * sampleCount);

  results.time.sampling = results.time.sampling * ...
    sampleCount / results.samples.count;

  results.samples.count          = sampleCount;
  results.samples.burninCount    = burninCount;
  results.samples.effectiveCount = sampleCount - burninCount;

  results.samples.z      = results.samples.z     (:, 1:sampleCount);
  results.samples.muu    = results.samples.muu   (   1:sampleCount);
  results.samples.sigmau = results.samples.sigmau(   1:sampleCount);
  results.samples.sigmae = results.samples.sigmae(   1:sampleCount);

  results.fitness    = results.fitness   (1:sampleCount);
  results.acceptance = results.acceptance(1:sampleCount);

  c.printf('Inference: done in %.2f minutes.\n', ...
    (results.time.optimization + results.time.sampling) / 60);

  %
  % Now, we really process the results.
  %

  z      = results.samples.z     (:, (burninCount + 1):end);
  muu    = results.samples.muu   (   (burninCount + 1):end);
  sigmau = results.samples.sigmau(   (burninCount + 1):end);
  sigmae = results.samples.sigmae(   (burninCount + 1):end);

  u = zeros(c.system.processorCount, ...
    c.system.wafer.dieCount, results.samples.effectiveCount);
  n = zeros(c.system.processorCount, ...
    c.system.wafer.dieCount, results.samples.effectiveCount);

  for i = 1:results.samples.effectiveCount
    [ u(:, :, i), n(:, :, i) ] = ...
      c.process.compute(z(:, i), muu(i), sigmau(i));
  end

  %
  % The average values.
  %
  results.mean = struct;
  results.mean.z      = mean(z, 2);
  results.mean.muu    = mean(muu);
  results.mean.sigmau = mean(sigmau);
  results.mean.sigmae = mean(sigmae);
  [ results.mean.u, results.mean.n ] = c.process.compute( ...
    results.mean.z, results.mean.muu, results.mean.sigmau);

  %
  % The standard deviations.
  %
  results.deviation = struct;
  results.deviation.z      = std(z, [], 2);
  results.deviation.muu    = std(muu);
  results.deviation.sigmau = std(sigmau);
  results.deviation.sigmae = std(sigmae);
  results.deviation.u      = std(u, [], 3);
  results.deviation.n      = std(n, [], 3);

  %
  % Finally, the error.
  %
  results.error = Error.computeNRMSE(m.n, results.mean.n);
end
