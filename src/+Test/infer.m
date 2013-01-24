function [ samples, acceptCount ] = infer(c, m)
  nodeCount = c.surrogate.nodeCount;
  sampleCount = c.inference.sampleCount;
  dimensionCount = c.dimensionCount;

  Pdyn = c.power.Pdyn;
  leakage = c.leakage.model;
  L = c.process.model.constrainMapping(m.dieIndex);
  timeIndex = m.timeIndex;
  processorCount = c.system.processorCount;
  stepCount = c.observations.timeCount;
  dieCount = c.observations.dieCount;

  inputCount = processorCount * dieCount;
  outputCount = processorCount * stepCount * dieCount;

  qmeasT = m.Tmeas(:)';

  verbose = @(varargin) fprintf(varargin{:});

  %
  % Temperature simulator.
  %
  hotspot = HotSpot.Batch('floorplan', c.system.floorplan, ...
    'config', c.temperature.configuration, 'line', c.temperature.line);

  %
  % The priors.
  %
  mu0     = c.inference.mu0;
  sigma20 = c.inference.sigma0.^2;

  nuu     = c.inference.nuu;
  tau2u   = c.inference.tauu.^2;

  nue     = c.inference.nue;
  tau2e   = c.inference.taue.^2;

  function result = computeLogPosterior( ...
    qT, muu, sigma2u, sigma2e, z, sigma2q)

    result = ...
      - (outputCount / 2) * log(sigma2e + sigma2q) * ...
      - sum((qmeasT - qT).^2) / (sigma2e + sigma2q) / 2 ...
      - (muu - mu0)^2 / sigma20 / 2 ...
      - (1 + nuu / 2) * log(sigma2u) ...
      - nuu * tau2u / sigma2u / 2 ...
      - (1 + nue / 2) * log(sigma2e) ...
      - nue * tau2e / sigma2e / 2 ...
      - sum(z.^2) / 2;
  end

  samples = zeros(sampleCount, 3 + dimensionCount);
  nodes = zeros(nodeCount, inputCount);
  responses = zeros(nodeCount, outputCount);

  %
  % The initial state of the chain.
  %
  muu     = mu0;
  sigma2u = tau2u^2;
  sigma2e = tau2e^2;
  z       = zeros(dimensionCount, 1);

  %
  % The proposal distribution.
  %
  sigmamuu    = c.inference.proposalRate * muu;
  sigmasigmau = c.inference.proposalRate * sqrt(sigma2u);
  sigmasigmae = c.inference.proposalRate * sqrt(sigma2e);
  sigmaz      = c.inference.proposalRate * ones(dimensionCount, 1);

  %
  % The first one is special.
  %
  u = muu + sqrt(sigma2u) * L * z;
  qT = hotspot.compute(Pdyn, timeIndex, leakage, u);

  sample = [ muu, sigma2u, sigma2e, z' ];
  logPosterior = computeLogPosterior( ...
    qT, muu, sigma2u, sigma2e, z, 0);

  acceptCount = 0;

  for i = 1:sampleCount
    verbose('Metropolis: %6d iteration, total %6d, accepted %6.2f%%.\n', ...
      i, sampleCount, acceptCount / i * 100);

    %
    % Sample the proposal distribution.
    %
    muu     =       sample(1    )  + sigmamuu    * randn;
    sigma2u = (sqrt(sample(2    )) + sigmasigmau * randn)^2;
    sigma2e = (sqrt(sample(3    )) + sigmasigmae * randn)^2;
    z       =       sample(4:end)' + sigmaz     .* randn(dimensionCount, 1);

    %
    % Compute the QoI.
    %
    u = muu + sqrt(sigma2u) * L * z;

    %
    % Obtain the model prediction.
    %
    if i <= nodeCount
      %
      % Sample the true model.
      %
      qT = hotspot.compute(Pdyn, timeIndex, leakage, u);
      sigma2q = 0;

      nodes(i, :) = u;
      responses(i, :) = qT;

      if i == nodeCount
        surrogate = Test.substitute(c, m, nodes, responses);
      end
    else
      %
      % Sample the surrogate.
      %
      [ qT, sigma2q ] = surrogate.evaluate(u);
    end

    %
    % Compute the log-posterior.
    %
    proposedLogPosterior = computeLogPosterior( ...
      qT, muu, sigma2u, sigma2e, z, sigma2q);

    %
    % Accept or reject?
    %
    if log(rand) < (proposedLogPosterior - logPosterior)
      %
      % Accept!
      %
      sample = [ muu, sigma2u, sigma2e, z' ];
      logPosterior = proposedLogPosterior;
      acceptCount = acceptCount + 1;
    end

    %
    % Save the sample.
    %
    samples(i, :) = sample;
  end
end
