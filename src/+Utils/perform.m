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
  samples.muu = muu;
  samples.sigma2u = sigma2u;
  samples.sigma2e = sigma2e;

  samples.fitness = fitness;
  samples.acceptance = acceptance;

  burnCount = round(c.inference.burninRate * count);

  z = mean(z(:, burnCount:end), 2);
  [ u, n ] = c.process.compute(z);

  muu = mean(muu(burnCount:end));
  sigma2u = mean(sigma2u(burnCount:end));
  sigma2e = mean(sigma2e(burnCount:end));

  results = Options;
  results.time = time;

  results.z = z;
  results.n = n;
  results.u = u;

  results.muu = muu;
  results.sigma2u = sigma2u;
  results.sigma2e = sigma2e;

  results.error = Error.computeNRMSE(m.n, n);
end
