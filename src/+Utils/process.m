function results = process(c, m, results, sampleCount)
  %
  % NOTE: Here, we introduce a possibility of shrinking
  % the number of samples that we would like to consider.
  %
  if ~exist('sampleCount', 'var'), sampleCount = c.inference.sampleCount; end

  assert(sampleCount <= c.inference.sampleCount);

  burninCount = round(c.inference.burninRate * sampleCount);
  effectiveCount = sampleCount - burninCount;

  results.time.sampling = results.time.sampling * ...
    sampleCount / c.inference.sampleCount;

  results.samples.z      = results.samples.z     (:, 1:sampleCount);
  results.samples.muu    = results.samples.muu   (   1:sampleCount);
  results.samples.sigmau = results.samples.sigmau(   1:sampleCount);
  results.samples.sigmae = results.samples.sigmae(   1:sampleCount);

  results.logPosterior = results.logPosterior(1:sampleCount);
  results.acceptance   = results.acceptance  (1:sampleCount);

  %
  % Burn the excess!
  %
  z      = results.samples.z     (:, (burninCount + 1):end);
  muu    = results.samples.muu   (   (burninCount + 1):end);
  sigmau = results.samples.sigmau(   (burninCount + 1):end);
  sigmae = results.samples.sigmae(   (burninCount + 1):end);

  u = zeros(c.system.processorCount, ...
    c.system.wafer.dieCount, effectiveCount);
  n = zeros(c.system.processorCount, ...
    c.system.wafer.dieCount, effectiveCount);

  for i = 1:effectiveCount
    [ u(:, :, i), n(:, :, i) ] = ...
      c.process.compute(z(:, i), muu(i), sigmau(i));
  end

  %
  % The mean.
  %
  Mean = struct;
  Mean.z      = mean(z, 2);
  Mean.muu    = mean(muu);
  Mean.sigmau = mean(sigmau);
  Mean.sigmae = mean(sigmae);
  [ Mean.u, Mean.n ] = c.process.compute(Mean.z, Mean.muu, Mean.sigmau);

  %
  % The standard deviations.
  %
  Deviation = struct;
  Deviation.z      = std(z, [], 2);
  Deviation.muu    = std(muu);
  Deviation.sigmau = std(sigmau);
  Deviation.sigmae = std(sigmae);
  Deviation.u      = std(u, [], 3);
  Deviation.n      = std(n, [], 3);

  results.mean = Mean;
  results.deviation = Deviation;
  results.error = Error.computeNRMSE(m.n, Mean.n);
end
