function [ Samples, Fitness, acceptCount ] = infer(c, m, model)
  if c.verbose
    verbose = @(varargin) fprintf(varargin{:});
  else
    verbose = @(varargin) [];
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
  % The proposal distribution.
  %
  proposalSigma = c.inference.proposalRate * ...
    [ ones(dimensionCount, 1); 0; 0; 0 ];

  %
  % The first sample is special.
  %
  node = computeNode(z, muu, sigma2u);
  qT = model.compute(node);

  sample = [ z; muu; sigma2u; sigma2e ];
  fitness = computeFitness(qT, 0, z, muu, sigma2u, sigma2e);

  acceptCount = 0;

  for i = 1:sampleCount
    if mod(i, 10) == 0
      verbose('Metropolis: finished %6.2f%%, accepted %6.2f%%.\n', ...
        i / sampleCount * 100, acceptCount / i * 100);
    end

    %
    % Sample the proposal distribution.
    %
    proposalSample = sample + ...
      proposalSigma .* randn(dimensionCount + 3, 1);

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
      [ qT, sigma2q ] = surrogate.evaluate(node);
    else
      %
      % Sampling the surrogate.
      %
      [ qT, sigma2q ] = surrogate.evaluate(node);
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
      acceptCount = acceptCount + 1;
    end

    %
    % Save the result.
    %
    Samples(i, :) = sample;
    Fitness(i) = fitness;
  end

  %
  % Do not forget to denormalize the result!
  %
  Samples(:, end - 2) = nmu + nsigma   * Samples(:, end - 2);
  Samples(:, end - 1) =       nsigma^2 * Samples(:, end - 1);
end
