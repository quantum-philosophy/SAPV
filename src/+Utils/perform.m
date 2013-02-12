function results = perform(c, m)
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

  c.printf('Inference: done in %.2f minutes.\n', time / 60);

  burnCount = round(c.inference.burninRate * c.inference.sampleCount);

  z      = results.samples.z     (:, burnCount:end);
  muu    = results.samples.muu   (   burnCount:end);
  sigmau = results.samples.sigmau(   burnCount:end);
  sigmae = results.samples.sigmae(   burnCount:end);

  sampleCount = c.inference.sampleCount - burnCount;
  measurementCount = c.observations.dieCount * ...
    c.system.processorCount * c.observations.timeCount;

  u = zeros(c.system.processorCount, c.system.wafer.dieCount, sampleCount);
  n = zeros(c.system.processorCount, c.system.wafer.dieCount, sampleCount);

  for i = 1:sampleCount
    [ u(:, :, i), n(:, :, i) ] = c.process.compute(z(:, i), muu(i), sigmau(i));
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

  results.time = time;
  results.mean = Mean;
  results.deviation = Deviation;
  results.error = Error.computeNRMSE(m.n, results.mean.n);
end
