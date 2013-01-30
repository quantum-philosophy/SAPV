function [ Samples, Fitness, Acceptance ] = infer(c, m, model)
  verbose = c.verbose;

  if verbose
    printf = @(varargin) fprintf(varargin{:});
  else
    printf = @(varargin) [];
  end

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

  if c.inference.optimizationStepCount > 0
    %
    % Optimization.
    %
    options.MaxFunEvals = c.inference.optimizationStepCount;
    options.LargeScale = 'off';

    if verbose
      options.Display = 'iter';
    else
      options.Display = 'off';
    end

    theta = [ z; muu; sqrt(sigma2u); sqrt(sigma2e) ];

    if File.exist('hessian.mat')
      printf('Optimization: loading the previously computed hessian.\n');
      load('hessian.mat');
    else
      time = tic; printf('Optimization: in progress...\n');
      [ theta, ~, ~, ~, ~, hessian ] = fminunc( ...
        @target, theta, options);
      printf('Optimization: done in %.2f seconds.\n', toc(time));
      save('hessian.mat', 'theta', 'hessian', '-v7.3');
    end

    [ U, L ] = eig(hessian);

    proposalSigma = U * diag(1 ./ sqrt(abs(diag(L))));

    sample = theta;
    sample(end - 1) = sample(end - 1)^2;
    sample(end - 0) = sample(end - 0)^2;

    %
    % Reset the last ones for now.
    %
    sample(end - 2) = muu;
    sample(end - 1) = sigma2u;
    sample(end - 0) = sigma2e;
    proposalSigma((end - 2):(end - 0), :) = 0;
    proposalSigma(:, (end - 2):(end - 0)) = 0;

    proposalSigma = c.inference.proposalRate * proposalSigma;
  else
    %
    % No optimization.
    %
    proposalSigma = c.inference.proposalRate * ...
      diag([ ones(dimensionCount, 1); 0; 0; 0 ]);

    sample = [ z; muu; sigma2u; sigma2e ];
  end

  fitness = -Inf;
  Acceptance = logical(zeros(1, sampleCount));

  stallStepCount = c.inference.stallStepCount;

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

    %
    % Stall?
    %
    if stallStepCount <= i && ...
      sum(Acceptance((i - stallStepCount + 1):i)) == 0

      printf('Metropolis: premature stopping as none is accepted during the last %d steps.\n', ...
        stallStepCount);
      sampleCount = i;
      break;
    end

    if verbose && mod(i, 1e2) == 0
      finished = 100 * i / sampleCount;
      accepted = 100 * mean(Acceptance(1:i));
      rate     = 100 * mean(Acceptance((i - 1e2 + 1):i));
      printf('Metropolis: finished %6.2f%%, accepted %6.2f%%, rate %6.2f%%.\n', ...
        finished, accepted, rate);
    end
  end

  printf('Metropolis: done in %.2f seconds.\n', toc(time));

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
