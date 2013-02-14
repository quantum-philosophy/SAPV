function results = perform(c, m, sampleCount)
  filename = c.stamp('inference.mat');
  if File.exist(filename);
    c.printf('Inference: loading cached data in "%s"...\n', filename);
    load(filename);
  else
    %% Initialize the forward model.
    %
    model = Utils.forward(c, 'model', 'observed');

    %% Do the inference.
    %
    time = tic;
    results = Utils.infer(c, m, model);
    time = toc(time);

    save(filename, 'time', 'results', '-v7.3');
  end

  %
  % Here, we introduce a possibility of shrinking the number
  % samples that we would like to consider.
  %
  if nargin < 3, sampleCount = c.inference.sampleCount; end

  assert(sampleCount <= c.inference.sampleCount);

  results.samples.z      = results.samples.z     (:, 1:sampleCount);
  results.samples.muu    = results.samples.muu   (   1:sampleCount);
  results.samples.sigmau = results.samples.sigmau(   1:sampleCount);
  results.samples.sigmae = results.samples.sigmae(   1:sampleCount);

  results.fitness    = results.fitness   (1:sampleCount);
  results.acceptance = results.acceptance(1:sampleCount);

  time = time * sampleCount / c.inference.sampleCount;

  %
  % Now, we process the results!
  %
  c.printf('Inference: done in %.2f minutes.\n', time / 60);

  burnCount = round(c.inference.burninRate * sampleCount);

  z      = results.samples.z     (:, (burnCount + 1):end);
  muu    = results.samples.muu   (   (burnCount + 1):end);
  sigmau = results.samples.sigmau(   (burnCount + 1):end);
  sigmae = results.samples.sigmae(   (burnCount + 1):end);

  effectiveSampleCount = sampleCount - burnCount;

  u = zeros(c.system.processorCount, ...
    c.system.wafer.dieCount, effectiveSampleCount);
  n = zeros(c.system.processorCount, ...
    c.system.wafer.dieCount, effectiveSampleCount);

  for i = 1:effectiveSampleCount
    [ u(:, :, i), n(:, :, i) ] = ...
      c.process.compute(z(:, i), muu(i), sigmau(i));
  end

  %
  % The average values.
  %
  Mean.z      = mean(z, 2);
  Mean.muu    = mean(muu);
  Mean.sigmau = mean(sigmau);
  Mean.sigmae = mean(sigmae);
  [ Mean.u, Mean.n ] = c.process.compute(Mean.z, Mean.muu, Mean.sigmau);

  %
  % The standard deviations.
  %
  Deviation.z      = std(z, [], 2);
  Deviation.muu    = std(muu);
  Deviation.sigmau = std(sigmau);
  Deviation.sigmae = std(sigmae);
  Deviation.u      = std(u, [], 3);
  Deviation.n      = std(n, [], 3);

  results.sampleCount = sampleCount;
  results.effectiveSampleCount = effectiveSampleCount;

  results.time = time;
  results.mean = Mean;
  results.deviation = Deviation;
  results.error = Error.computeNRMSE(m.n, results.mean.n);
end
