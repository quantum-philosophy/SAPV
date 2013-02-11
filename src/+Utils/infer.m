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
  mu0    = c.inference.mu0;
  sigma0 = c.inference.sigma0;

  nuu  = c.inference.nuu;
  tauu = c.inference.tauu;

  nue  = c.inference.nue;
  taue = c.inference.taue;

  %
  % NOTE: The inference we do is for the normalized parameters.
  %

  function result = computeNode(z_, muun_, sigmaun_)
    result = (mu0 + sigma0 * muun_) + tauu * sigmaun_ * mapping * z_;
  end

  function result = computeFitness( ...
    qT_, sigma2q_, z_, muun_, sigmaun_, sigmaen_)

    muu_     = mu0 + sigma0 * muun_;
    sigma2u_ = (tauu * sigmaun_)^2;
    sigma2e_ = (taue * sigmaen_)^2;

    result = ...
      - (outputCount / 2) * log(sigma2e_ + sigma2q_) ...
      - sum((qmeasT - qT_).^2) / (sigma2e_ + sigma2q_) / 2 ...
      ...
      - sum(z_.^2) / 2 ...
      ...
      - (muu_ - mu0)^2 / sigma0^2 / 2 ...
      ...
      - (1 + nuu / 2) * log(sigma2u_) ...
      - nuu * tauu^2 / sigma2u_ / 2 ...
      ...
      - (1 + nue / 2) * log(sigma2e_) ...
      - nue * taue^2 / sigma2e_ / 2;
  end

  samples = zeros(sampleCount, dimensionCount + 3);
  fitness = zeros(sampleCount, 1);

  %
  % Initial values and the proposal distribution.
  %
  fixMuu    = c.inference.fixMuu;
  fixSigmau = c.inference.fixSigmau;
  fixSigmae = c.inference.fixSigmae;

  function theta_ = encode(z_, muun_, sigmaun_, sigmaen_)
    theta_ = z_;
    if ~fixMuu,    theta_ = [ theta_; muun_    ]; end
    if ~fixSigmau, theta_ = [ theta_; sigmaun_ ]; end
    if ~fixSigmae, theta_ = [ theta_; sigmaen_ ]; end
  end

  function [ z_, muun_, sigmaun_, sigmaen_ ] = decode(theta_)
    z_ = theta_(1:dimensionCount);

    k = dimensionCount + 1;

    if fixMuu, muun_ = 0;
    else muun_ = theta_(k); k = k + 1; end

    if fixSigmau, sigmaun_ = 1;
    else sigmaun_ = theta_(k)^2; k = k + 1; end

    if fixSigmae, sigmaen_ = 1;
    else sigmaen_ = theta_(k)^2; end
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

    if ~fixSigmau
      I = [ I l ];
      proposalSigma__(l, I) = proposalSigma_(k, 1:k);
      proposalSigma__(I, l) = proposalSigma_(1:k, k);
      k = k + 1;
    end
    l = l + 1;

    if ~fixSigmae
      I = [ I l ];
      proposalSigma__(l, I) = proposalSigma_(k, 1:k);
      proposalSigma__(I, l) = proposalSigma_(1:k, k);
    end
  end

  function result = target(theta_)
    [ z_, muun_, sigmaun_, sigmaen_ ] = decode(theta_);

    node_ = computeNode(z_, muun_, sigmaun_);
    qT_ = model.compute(node_);

    result = -computeFitness( ...
      qT_, 0, z_, muun_, sigmaun_, sigmaen_);
  end

  %
  % Construct a proposal distribution.
  %
  filename = c.stamp('proposal.mat', qmeasT);
  if File.exist(filename)
    c.printf('Proposal: loading cached data in "%s".\n', filename);
    load(filename);
  else
    method = lower(c.inference.optimization.method);

    c.printf('Proposal: in progress using "%s"...\n', method);
    time = tic;

    theta = encode(zeros(dimensionCount, 1), 0, 1, 1);

    switch method
    case 'none'
      %
      % No optimization.
      %
      covariance = eye(length(theta));
      proposalCoefficient = covariance;
    case 'csminwel'
      %
      % Using the library suggested by Mattias.
      %
      options = Options;
      options.verbose = verbose;
      options.maximalFunctionCount = c.inference.optimization.maximalStepCount;
      options.stallThreshold = c.inference.optimization.stallThreshold;

      [ ~, theta, ~, covariance ] = csminwel( ...
        @target, theta, 1e-4 * eye(length(theta)), [], options);

      %
      % Now, we have the inverse Hessian matrix at a posterior mode,
      % and we need to turn into a Cholesky-like multiplier.
      %
      proposalCoefficient = chol(covariance, 'lower');
    case 'fminunc'
      %
      % Using MATLAB's facilities.
      %
      options.MaxFunEvals = c.inference.optimization.maximalStepCount;
      options.TolFun = c.inference.optimization.stallThreshold;
      options.LargeScale = 'off';
      if verbose, options.Display = 'iter';
      else options.Display = 'off'; end

      [ theta, ~, ~, ~, ~, hessian ] = fminunc( ...
        @target, theta, options);

      %
      % Now, we have the Hessian matrix at a posterior mode, and
      % we need to invert it and turn into a Cholesky-like multiplier.
      %
      [ U, L ] = eig(hessian);
      L = diag(L);

      covariance = U * diag(1 ./ abs(L)) * U';
      proposalCoefficient = U * diag(1 ./ sqrt(abs(L)));

      c.printf('Proposal: %d out of %d eigenvalues are negative.\n', ...
        sum(L < 0), length(L));
    otherwise
      assert(false);
    end

    %
    % Assessment of the quality of the constructed proposal distribution.
    %
    if c.inference.assessProposal
      c.printf('Proposal: assessment using %d extra points in each direction...\n', ...
        c.inference.assessmentPointCount);
      assessment = Utils.performProposalAssessment( ...
        @(theta_) -target(theta_), theta, covariance, ...
        'pointCount', c.inference.assessmentPointCount);
    else
      assessment = [];
    end

    time = toc(time);

    save(filename, 'time', 'theta', 'covariance', ...
      'proposalCoefficient', 'assessment', '-v7.3');
  end

  c.printf('Proposal: done in %.2f minutes.\n', time / 60);

  %
  % NOTE: Do not forget about the tuning constant!
  %
  proposalCoefficient = c.inference.proposalRate * adjust(proposalCoefficient);

  %
  % Initial values.
  %
  currentFitness = -Inf;
  [ z, muun, sigmaun, sigmaen ] = decode(theta);
  currentSample = [ z; muun; sigmaun; sigmaen ];
  proposalSample = currentSample;

  acceptance = logical(zeros(1, sampleCount));

  time = tic;

  for i = 1:sampleCount
    %
    % Process the proposed sample.
    %
    z       = proposalSample(1:(end - 3));
    muun    = proposalSample(   end - 2);
    sigmaun = proposalSample(   end - 1);
    sigmaen = proposalSample(   end - 0);

    node = computeNode(z, muun, sigmaun);

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
      qT, sigma2q, z, muun, sigmaun, sigmaen);

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
      proposalCoefficient * randn(dimensionCount + 3, 1);
  end

  c.printf('Metropolis: done with %d samples in %.2f seconds.\n', ...
    sampleCount, toc(time));

  %
  % Do not forget to denormalize the result!
  %
  samples(:, end - 2) = mu0 + sigma0 * samples(:, end - 2);
  samples(:, end - 1) =         tauu * samples(:, end - 1);
  samples(:, end - 0) =         taue * samples(:, end - 0);

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
  results.samples.z      =     samples(:,  1:(end - 3))';
  results.samples.muu    =     samples(:,     end - 2)';
  results.samples.sigmau = abs(samples(:,     end - 1))';
  results.samples.sigmae = abs(samples(:,     end - 0))';

  % Progress
  results.fitness    = fitness;
  results.acceptance = acceptance;
end
