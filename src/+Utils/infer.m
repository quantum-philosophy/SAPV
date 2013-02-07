function results = infer(c, m, model)
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

  samples = zeros(sampleCount, dimensionCount + 3);
  fitness = zeros(sampleCount, 1);

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
  fixMuu     = c.inference.fixMuu;
  fixSigma2u = c.inference.fixSigma2u;
  fixSigma2e = c.inference.fixSigma2e;

  function theta_ = encode(z_, muu_, sigma2u_, sigma2e_)
    theta_ = z_;
    if ~fixMuu,     theta_ = [ theta_; muu_           ]; end
    if ~fixSigma2u, theta_ = [ theta_; sqrt(sigma2u_) ]; end
    if ~fixSigma2e, theta_ = [ theta_; sqrt(sigma2e_) ]; end
  end

  function [ z_, muu_, sigma2u_, sigma2e_ ] = decode(theta_)
    z_ = theta_(1:dimensionCount);

    k = dimensionCount + 1;

    if fixMuu, muu_ = muu;
    else muu_ = theta_(k); k = k + 1; end

    if fixSigma2u, sigma2u_ = sigma2u;
    else sigma2u_ = theta_(k)^2; k = k + 1; end

    if fixSigma2e, sigma2e_ = sigma2e;
    else sigma2e_ = theta_(k)^2; end
  end

  function sample_ = pack(theta_)
    [ z_, muu_, sigma2u_, sigma2e_ ] = decode(theta_);
    sample_ = [ z_; muu_; sigma2u_; sigma2e_ ];
  end

  function proposalSigma__ = adjust(proposalSigma_)
    proposalSigma__ = zeros(dimensionCount + 3);

    proposalSigma__(1:dimensionCount, 1:dimensionCount) = ...
      proposalSigma_(1:dimensionCount, 1:dimensionCount);

    l = dimensionCount + 1;
    k = dimensionCount + 1;
    I = 1:dimensionCount;

    if ~fixMuu
      I = [ I l ];
      proposalSigma__(l, I) = proposalSigma_(k, 1:k);
      proposalSigma__(I, l) = proposalSigma_(1:k, k);
      k = k + 1;
    end
    l = l + 1;

    if ~fixSigma2u
      I = [ I l ];
      proposalSigma__(l, I) = proposalSigma_(k, 1:k);
      proposalSigma__(I, l) = proposalSigma_(1:k, k);
      k = k + 1;
    end
    l = l + 1;

    if ~fixSigma2e
      I = [ I l ];
      proposalSigma__(l, I) = proposalSigma_(k, 1:k);
      proposalSigma__(I, l) = proposalSigma_(1:k, k);
    end
  end

  function result = target(theta_)
    [ z_, muu_, sigma2u_, sigma2e_ ] = decode(theta_);

    node_ = computeNode(z_, muu_, sigma2u_);
    qT_ = model.compute(node_);

    result = -computeFitness( ...
      qT_, 0, z_, muu_, sigma2u_, sigma2e_);
  end

  %
  % Optimize?
  %
  switch lower(c.inference.optimization.method)
  case 'none'
    %
    % No optimization.
    %
    theta = [ z; muu; sqrt(sigma2u); sqrt(sigma2e) ];
    currentSample = [ z; muu; sigma2u; sigma2e ];

    variance = [ ...
      ones(1, dimensionCount), ...
      (fixMuu     == false) * sigma20, ...
      (fixSigma2u == false) * tau2u, ...
      (fixSigma2e == false) * tau2e ];

    proposalSigma = diag(sqrt(variance));

    I = find(variance > 0);
    theta = theta(I);
    covariance = diag(variance(I));
  case 'csminwel'
    %
    % Using the library suggested by Mattias.
    %
    filename = c.stamp('inverseHessian.mat', qmeasT);
    if File.exist(filename)
      c.printf('Optimization: loading the previously computed inverse Hessian.\n');
      load(filename);
    else
      theta = encode(z, muu, sigma2u, sigma2e);

      options = Options;
      options.verbose = verbose;
      options.maximalFunctionCount = c.inference.optimization.maximalStepCount;
      options.stallThreshold = c.inference.optimization.stallThreshold;

      c.printf('Optimization: in progress...\n');

      time = tic;
      [ objective, theta, ~, inverseHessian ] = csminwel( ...
        @target, theta, 1e-4 * eye(length(theta)), [], options);
      time = toc(time);

      save(filename, 'time', 'objective', 'theta', 'inverseHessian', '-v7.3');
    end

    c.printf('Optimization: done in %.2f minutes.\n', time / 60);

    currentSample = pack(theta);

    %
    % Now, we have the inverse Hessian matrix at a posterior mode,
    % and we need to turn into a Cholesky-like multiplier.
    %
    proposalSigma = adjust(chol(inverseHessian, 'lower'));
    covariance = inverseHessian;
  case 'fminunc'
    %
    % Using MATLAB's facilities.
    %
    filename = c.stamp('hessian.mat', qmeasT);
    if File.exist(filename)
      c.printf('Optimization: loading the previously computed Hessian.\n');
      load(filename);
    else
      theta = encode(z, muu, sigma2u, sigma2e);

      options.MaxFunEvals = c.inference.optimization.maximalStepCount;
      optinos.TolFun = c.inference.optimization.stallThreshold;
      options.LargeScale = 'off';
      if verbose, options.Display = 'iter';
      else options.Display = 'off'; end

      c.printf('Optimization: in progress...\n');

      time = tic;
      [ theta, objective ~, ~, ~, hessian ] = fminunc( ...
        @target, theta, options);
      time = toc(time);

      save(filename, 'time', 'theta', 'objective', 'hessian', '-v7.3');
    end

    c.printf('Optimization: done in %.2f minutes.\n', time / 60);

    currentSample = pack(theta);

    %
    % Now, we have the Hessian matrix at a posterior mode, and
    % we need to invert it and turn into a Cholesky-like multiplier.
    %
    [ U, L ] = eig(hessian);
    L = diag(L);
    proposalSigma = adjust(U * diag(1 ./ sqrt(abs(L))));
    covariance = U * diag(1 ./ abs(L)) * U';

    c.printf('Optimization: %d out of %d eigenvalues are negative.\n', ...
      sum(L < 0), length(L));
  otherwise
    assert(false);
  end

  if c.inference.assessProposal
    filename = c.stamp('assessment.mat', qmeasT);
    if File.exist(filename)
      c.printf('Assessment: loading the previously computed results.\n');
      load(filename);
    else
      c.printf('Assessment: in progress...\n');

      time = tic;
      assessment = Utils.assessProposalDistribution( ...
        @(theta_) -target(theta_), theta, covariance);
      time = toc(time);

      save(filename, 'time', 'assessment', '-v7.3');
    end
    c.printf('Assessment: done in %.2f seconds.\n', time);
  else
    assessment = [];
  end

  %
  % NOTE: Do not forget about the tuning constant!
  %
  proposalSigma = c.inference.proposalRate * proposalSigma;

  currentFitness = -Inf;
  proposalSample = currentSample;

  acceptance = logical(zeros(1, sampleCount));

  time = tic;

  for i = 1:sampleCount
    %
    % Process the proposed sample.
    %
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
    if log(rand) < (proposalFitness - currentFitness)
      %
      % Accept!
      %
      currentSample = proposalSample;
      currentFitness = proposalFitness;
      acceptance(i) = true;
    end

    %
    % Save the result.
    %
    samples(i, :) = currentSample;
    fitness(i) = currentFitness;

    if verbose && mod(i, 1e2) == 0
      finished = 100 * i / sampleCount;
      accepted = 100 * mean(acceptance(1:i));
      rate     = 100 * mean(acceptance((i - 1e2 + 1):i));
      c.printf('Metropolis: finished %6.2f%% (%6d/%6d), accepted %5.2f%%, rate %5.2f%%, fitness %10.2f.\n', ...
        finished, i, sampleCount, accepted, rate, currentFitness);
    end

    %
    % Propose a new sample!
    %
    proposalSample = currentSample + ...
      proposalSigma * randn(dimensionCount + 3, 1);
  end

  c.printf('Metropolis: done with %d samples in %.2f seconds.\n', ...
    sampleCount, toc(time));

  %
  % Do not forget to denormalize the result!
  %
  samples(:, end - 2) = nmu + nsigma   * samples(:, end - 2);
  samples(:, end - 1) =       nsigma^2 * samples(:, end - 1);

  %
  % Truncate the output.
  %
  results = Options;

  % Optimization
  results.theta      = theta;
  results.covariance = covariance;
  results.assessment = assessment;

  % Sampling
  results.samples = Options;
  results.samples.z       = samples(:, 1:(end - 3))';
  results.samples.muu     = samples(:,    end - 2)';
  results.samples.sigma2u = samples(:,    end - 1)';
  results.samples.sigma2e = samples(:,    end - 0)';

  % Progress
  results.fitness    = fitness;
  results.acceptance = acceptance;
end
