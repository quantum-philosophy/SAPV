function [ Samples, Fitness, acceptCount ] = infer(varargin)
  options = Options(varargin{:});

  qmeasT = transpose(options.data(:));
  model = options.model;

  outputCount = length(qmeasT);
  dimensionCount = model.dimensionCount;
  sampleCount = options.sampleCount;

  if options.get('verbose', false)
    verbose = @(varargin) fprintf(varargin{:});
  else
    verbose = @(varargin) [];
  end

  %
  % The priors.
  %
  mu0     = options.mu0;
  sigma20 = options.sigma0^2;

  nuu     = options.nuu;
  tau2u   = options.tauu^2;

  nue     = options.nue;
  tau2e   = options.taue^2;

  function result = computeFitness( ...
    qT, sigma2q, muu, sigma2u, sigma2e, z)

    result = ...
      - (outputCount / 2) * log(sigma2e + sigma2q) ...
      - sum((qmeasT - qT).^2) / (sigma2e + sigma2q) / 2 ...
      - (muu - mu0)^2 / sigma20 / 2 ...
      - (1 + nuu / 2) * log(sigma2u) ...
      - nuu * tau2u / sigma2u / 2 ...
      - (1 + nue / 2) * log(sigma2e) ...
      - nue * tau2e / sigma2e / 2 ...
      - sum(z.^2) / 2;
  end

  Samples = zeros(sampleCount, 3 + dimensionCount);
  Fitness = zeros(sampleCount, 1);

  %
  % NOTE: In what follows, it is assumed that everything
  % is normalized.
  %

  %
  % The initial state of the chain.
  %
  muu     = 0;
  sigma2u = 1;
  sigma2e = 1;
  z       = zeros(dimensionCount, 1);

  %
  % The proposal distribution.
  %
  proposalSigma = options.proposalRate * ...
    ones(3 + dimensionCount, 1);

  %
  % The first sample is special.
  %
  qT = model.compute(z, muu, sigma2u);

  sample = [ muu; sigma2u; sigma2e; z ];
  fitness = computeFitness(qT, 0, muu, sigma2u, sigma2e, z);

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
      proposalSigma .* randn(3 + dimensionCount, 1);

    muu     = proposalSample(1);
    sigma2u = proposalSample(2);
    sigma2e = proposalSample(3);
    z       = proposalSample(4:end);

    %
    % Sample the forward model.
    %
    [ qT, sigma2q ] = model.compute(z, muu, sigma2u);

    %
    % Compute the fitness, which is proportional to the log-posterior.
    %
    proposalFitness = computeFitness( ...
      qT, sigma2q, muu, sigma2u, sigma2e, z);

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
end
