function [ Samples, Fitness, acceptCount ] = infer(varargin)
  options = Options(varargin{:});

  if options.get('verbose', false)
    verbose = @(varargin) fprintf(varargin{:});
  else
    verbose = @(varargin) [];
  end

  qmeasT = transpose(options.data(:));
  model = options.model;

  outputCount = length(qmeasT);
  dimensionCount = model.process.dimensionCount;
  sampleCount = options.sampleCount;

  %
  % The priors.
  %
  mu0     = options.mu0;
  sigma20 = options.sigma20;

  nuu     = options.nuu;
  tau2u   = options.tau2u;

  nue     = options.nue;
  tau2e   = options.tau2e;

  %
  % Normalization (excluding the noise).
  %
  nmu    = options.mu0;
  nsigma = sqrt(options.tau2u);

  mu0     = (mu0 - nmu) / nsigma;
  sigma20 = sigma20     / nmu^2;
  tau2u   = tau2u       / nsigma^2;

  assert(mu0     == 0);
  assert(tau2u   == 1);

  function result = computeFitness( ...
    qT, sigma2q, z, muu, sigma2u, sigma2e)

    result = ...
      - (outputCount / 2) * log(sigma2e + sigma2q) ...
      - sum((qmeasT - qT).^2) / (sigma2e + sigma2q) / 2 ...
      ...
      - sum(z.^2) / 2 ...
      ...
      - (muu - mu0)^2 / sigma20 / 2 ...
      ...
      - (1 + nuu / 2) * log(sigma2u) ...
      - nuu * tau2u / sigma2u / 2 ...
      ...
      - (1 + nue / 2) * log(sigma2e) ...
      - nue * tau2e / sigma2e / 2;
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
  proposalSigma = options.proposalRate * ...
    [ ones(dimensionCount, 1); 0; 0; 0 ];

  %
  % The first sample is special.
  %
  qT = model.compute(z, ...
    nmu + nsigma * muu, nsigma^2 * sigma2u);

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

    %
    % Sample the forward model.
    %
    [ qT, sigma2q ] = model.compute(z, ...
      nmu + nsigma * muu, nsigma^2 * sigma2u);

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
