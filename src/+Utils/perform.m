function [ results, samples ] = perform(c, m)
  filename = c.stamp('inference.mat');
  if File.exist(filename);
    c.printf('Inference: loading cashed data in "%s"...\n', filename);
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

  results.time = time;

  results.z       = mean(results.samples.z(:, burnCount:end), 2);
  results.muu     = mean(results.samples.muu(burnCount:end));
  results.sigma2u = mean(results.samples.sigma2u(burnCount:end));
  results.sigma2e = mean(results.samples.sigma2e(burnCount:end));

  [ results.u, results.n ] = c.process.compute(results.z);

  results.error = Error.computeNRMSE(m.n, results.n);
end
