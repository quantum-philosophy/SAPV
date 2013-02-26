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

  for i = 1:effectiveCount
    u(:, :, i) = c.process.compute(z(:, i), muu(i), sigmau(i));
  end

  %
  % The mean.
  %
  Mean = struct;
  Mean.z      = mean(z, 2);
  Mean.muu    = mean(muu);
  Mean.sigmau = mean(sigmau);
  Mean.sigmae = mean(sigmae);
  Mean.u      = mean(u, 3);

  %
  % The standard deviations.
  %
  Deviation = struct;
  Deviation.z      = std(z, [], 2);
  Deviation.muu    = std(muu);
  Deviation.sigmau = std(sigmau);
  Deviation.sigmae = std(sigmae);
  Deviation.u      = std(u, [], 3);

  %
  % Decision making.
  %
  % The null hypothesis: the die is defective.
  %
  uLimit = c.process.mean - 2 * c.process.deviation;
  pLimit = 0.2;

  decision.probability = sum(min(u, [], 1) < uLimit, 3) / sampleCount;

  I = 1:c.system.wafer.dieCount;
  T = find(min(m.u, [], 1) < uLimit);
  D = find(decision.probability > pLimit);

  decision.trueIndex          = T;
  decision.falsePositiveIndex = setdiff(T, D); % Type I
  decision.falseNegativeIndex = setdiff(setdiff(I, T), setdiff(I, D)); % Type II
  decision.truePositiveIndex  = intersect(setdiff(I, T), setdiff(I, D));
  decision.trueNegativeIndex  = intersect(D, T);

  decision.trueCount          = length(decision.trueIndex);
  decision.falsePositiveCount = length(decision.falsePositiveIndex);
  decision.falseNegativeCount = length(decision.falseNegativeIndex);
  decision.truePositiveCount  = length(decision.truePositiveIndex);
  decision.trueNegativeCount  = length(decision.trueNegativeIndex);

  results.mean      = Mean;
  results.deviation = Deviation;
  results.decision  = decision;
  results.error     = Error.computeNRMSE(m.u, Mean.u);
end
