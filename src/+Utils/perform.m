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
    [ samples, fitness, acceptance ] = Utils.infer(c, m, model);
    time = toc(time);

    save(filename, 'time', 'samples', 'fitness', 'acceptance', '-v7.3');
  end

  c.printf('Inference: done in %.2f minutes.\n', time / 60);

  count = size(samples, 1);

  z       = samples(:, 1:(end - 3))';
  muu     = samples(:,    end - 2)';
  sigma2u = samples(:,    end - 1)';
  sigma2e = samples(:,    end - 0)';

  samples = Options;
  samples.count = count;
  samples.z = z;

  if length(unique(muu)) > 1, samples.muu = muu;
  else samples.muu = []; end

  if length(unique(sigma2u)) > 1, samples.sigma2u = sigma2u;
  else samples.sigma2u = []; end

  if length(unique(sigma2e)) > 1, samples.sigma2e = sigma2e;
  else samples.sigma2e = []; end

  samples.fitness = fitness;
  samples.acceptance = acceptance;

  %
  % NOTE: We are discarding 10% of the samples. May be we should
  % through away more?
  %
  z = mean(z(:, round(0.1 * count):end), 2);
  [ u, n ] = c.process.compute(z);

  results = Options;
  results.z = z;
  results.n = n;
  results.u = u;
  results.error = Error.computeNRMSE(m.n, n);
end
