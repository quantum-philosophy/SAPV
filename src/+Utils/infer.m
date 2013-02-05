function [ Samples, Fitness, Acceptance ] = infer(c, m, model)
  verbose = c.verbose;

  qmeasT = transpose(m.Tmeas(:));
  mapping = c.process.constrainMapping(c.observations.dieIndex);

  [ inputCount, dimensionCount ] = size(mapping);
  outputCount = length(qmeasT);
  sampleCount = c.inference.sampleCount;

  %
  % Surrogate?
  %
  nodeCount = c.surrogate.nodeCount;
  useSurrogate = ~isnan(nodeCount);

  if useSurrogate
    surrogate = NaN;
    nodeIndex = 0;
    nodes = zeros(nodeCount, inputCount);
    responses = zeros(nodeCount, outputCount);
  end

  %
  % The priors.
  %
  mu0     = c.inference.mu0;
  sigma20 = c.inference.sigma20;

  nuu     = c.inference.nuu;
  tau2u   = c.inference.tau2u;

  nue     = c.inference.nue;
  tau2e   = c.inference.tau2e;

  %
  % Normalization (excluding the noise).
  %
  nmu    = c.inference.mu0;
  nsigma = sqrt(c.inference.tau2u);

  mu0     = (mu0 - nmu) / nsigma;
  sigma20 = sigma20     / nmu^2;
  tau2u   = tau2u       / nsigma^2;

  assert(mu0   == 0);
  assert(tau2u == 1);

  function result = computeNode(z_, muu_, sigma2u_)
    result = (nmu + nsigma * muu_) + ...
      nsigma * sqrt(sigma2u_) * mapping * z_;
  end

  function result = computeFitness( ...
    qT_, sigma2q_, z_, muu_, sigma2u_, sigma2e_)

    result = ...
      - (outputCount / 2) * log(sigma2e_ + sigma2q_) ...
      - sum((qmeasT - qT_).^2) / (sigma2e_ + sigma2q_) / 2 ...
      ...
      - sum(z_.^2) / 2 ...
      ...
      - (muu_ - mu0)^2 / sigma20 / 2 ...
      ...
      - (1 + nuu / 2) * log(sigma2u_) ...
      - nuu * tau2u / sigma2u_ / 2 ...
      ...
      - (1 + nue / 2) * log(sigma2e_) ...
      - nue * tau2e / sigma2e_ / 2;
  end

  Samples = zeros(sampleCount, dimensionCount + 3);
  Fitness = zeros(sampleCount, 1);

  %
  % The initial state of the chain.
  %
  z       = zeros(dimensionCount, 1);
  muu     = mu0;
  sigma2u = tau2u;
  sigma2e = tau2e;

  %
  % Initial values and the proposal distribution.
  %
  function result = target(theta_)
    z_       = theta_(1:(end - 3));
    muu_     = theta_(   end - 2);
    sigma2u_ = theta_(   end - 1)^2;
    sigma2e_ = theta_(   end - 0)^2;

    node_ = computeNode(z_, muu_, sigma2u_);
    qT_ = model.compute(node_);

    result = -computeFitness( ...
      qT_, 0, z_, muu_, sigma2u_, sigma2e_);
  end

  %
  % Optimize?
  %
  switch lower(c.inference.optimizationMethod)
  case 'none'
    %
    % No optimization.
    %
    sample = [ z; muu; sigma2u; sigma2e ];
    proposalSigma = eye(dimensionCount + 3);
  case 'csminwel'
    %
    % Using the library suggested by Mattias.
    %
    filename = c.stamp('inverseHessian.mat');
    if File.exist(filename)
      c.printf('Optimization: loading the previously computed inverse Hessian.\n');
      load(filename);
    else
      theta = [ z; muu; sqrt(sigma2u); sqrt(sigma2e) ];

      options = Options;
      options.verbose = verbose;
      options.maximalIterationCount = c.inference.optimizationStepCount;
      options.stallThreshold = c.inference.optimizationStallThreshold;

      time = tic; c.printf('Optimization: in progress...\n');
      [ ~, theta, ~, inverseHessian ] = csminwel( ...
        @target, theta, 1e-4 * eye(length(theta)), [], options);
      time = toc(time);

      save(filename, 'time', 'theta', 'inverseHessian', '-v7.3');
    end

    c.printf('Optimization: done in %.2f minutes.\n', time / 60);

    %
    % Now, we have the inverse Hessian matrix at a posterior mode,
    % and we need to turn into a Cholesky-like multiplier.
    %
    proposalSigma = chol(inverseHessian, 'lower');

    sample = theta;
    sample(end - 1) = sample(end - 1)^2;
    sample(end - 0) = sample(end - 0)^2;
  case 'fminunc'
    %
    % Using MATLAB's facilities.
    %
    filename = c.stamp('hessian.mat');
    if File.exist(filename)
      c.printf('Optimization: loading the previously computed Hessian.\n');
      load(filename);
    else
      theta = [ z; muu; sqrt(sigma2u); sqrt(sigma2e) ];

      options.MaxFunEvals = c.inference.optimizationStepCount;
      options.LargeScale = 'off';
      if verbose, options.Display = 'iter';
      else options.Display = 'off'; end

      time = tic; c.printf('Optimization: in progress...\n');
      [ theta, ~, ~, ~, ~, hessian ] = fminunc( ...
        @target, theta, options);
      time = toc(time);

      save(filename, 'time', 'theta', 'hessian', '-v7.3');
    end

    c.printf('Optimization: done in %.2f minutes.\n', time / 60);

    %
    % Now, we have the Hessian matrix at a posterior mode, and
    % we need to invert it and turn into a Cholesky-like multiplier.
    %
    [ U, L ] = eig(hessian);
    L = diag(L);
    proposalSigma = U * diag(1 ./ sqrt(abs(L)));

    c.printf('Optimization: %d out of %d eigenvalues are negative.\n', ...
      sum(L < 0), length(L));

    sample = theta;
    sample(end - 1) = sample(end - 1)^2;
    sample(end - 0) = sample(end - 0)^2;
  otherwise
    assert(false);
  end

  %
  % NOTE: Do not forget about the tuning constant!
  %
  proposalSigma = c.inference.proposalRate * proposalSigma;

  %
  % Reset the last ones for now.
  %
  sample(end - 2) = muu;
  proposalSigma(end - 2, :) = 0;
  proposalSigma(:, end - 2) = 0;

  sample(end - 1) = sigma2u;
  proposalSigma(end - 1, :) = 0;
  proposalSigma(:, end - 1) = 0;

  sample(end - 0) = sigma2e;
  proposalSigma(end - 0, :) = 0;
  proposalSigma(:, end - 0) = 0;

  fitness = -Inf;
  Acceptance = logical(zeros(1, sampleCount));

  time = tic;

  for i = 1:sampleCount
    %
    % Sample the proposal distribution.
    %
    proposalSample = sample + ...
      proposalSigma * randn(dimensionCount + 3, 1);

    z       = proposalSample(1:(end - 3));
    muu     = proposalSample(   end - 2);
    sigma2u = proposalSample(   end - 1);
    sigma2e = proposalSample(   end - 0);

    node = computeNode(z, muu, sigma2u);

    if ~useSurrogate
      %
      % Regular sampling of the forward model.
      %
      qT = model.compute(node);
      sigma2q = 0;
    elseif i <= nodeCount
      %
      % Collecting data for the surrogate.
      %
      qT = model.compute(node);
      sigma2q = 0;

      nodeIndex = nodeIndex + 1;
      nodes(nodeIndex, :) = node;
      responses(nodeIndex, :) = qT;
    elseif i == nodeCount + 1
      %
      % Construct the surrogate and use it right away.
      %
      surrogate = Utils.substitute(c, nodes, responses);
      [ qT, sigma2q ] = surrogate.evaluate(node');
    else
      %
      % Sampling the surrogate.
      %
      [ qT, sigma2q ] = surrogate.evaluate(node');
    end

    %
    % Compute the fitness, which is proportional to the log-posterior.
    %
    proposalFitness = computeFitness( ...
      qT, sigma2q, z, muu, sigma2u, sigma2e);

    %
    % Accept or reject?
    %
    if log(rand) < (proposalFitness - fitness)
      %
      % Accept!
      %
      sample = proposalSample;
      fitness = proposalFitness;
      Acceptance(i) = true;
    end

    %
    % Save the result.
    %
    Samples(i, :) = sample;
    Fitness(i) = fitness;

    if verbose && mod(i, 1e2) == 0
      finished = 100 * i / sampleCount;
      accepted = 100 * mean(Acceptance(1:i));
      rate     = 100 * mean(Acceptance((i - 1e2 + 1):i));
      c.printf('Metropolis: finished %6.2f%%, accepted %5.2f%%, rate %5.2f%%, fitness %10.2f.\n', ...
        finished, accepted, rate, fitness);
    end
  end

  c.printf('Metropolis: done with %d samples in %.2f seconds.\n', ...
    sampleCount, toc(time));

  %
  % Do not forget to denormalize the result!
  %
  Samples(:, end - 2) = nmu + nsigma   * Samples(:, end - 2);
  Samples(:, end - 1) =       nsigma^2 * Samples(:, end - 1);

  %
  % Truncate the output.
  %
  Samples    = Samples   (1:sampleCount, :);
  Fitness    = Fitness   (1:sampleCount);
  Acceptance = Acceptance(1:sampleCount);
end
