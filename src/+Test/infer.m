function [ samples, fitness, acceptCount ] = infer(c, m)
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

  function result = computeFitness( ...
    qT, muu, sigma2u, sigma2e, z, sigma2q)

    a = - (outputCount / 2) * log(sigma2e + sigma2q);
    b = - sum((qmeasT - qT).^2) / (sigma2e + sigma2q) / 2;
    c = - (muu - mu0)^2 / sigma20 / 2;
    d = - (1 + nuu / 2) * log(sigma2u);
    e = - nuu * tau2u / sigma2u / 2;
    f = - (1 + nue / 2) * log(sigma2e);
    g = - nue * tau2e / sigma2e / 2;
    h = - sum(z.^2) / 2;

    result = a + b + c + d + e + f + g + h;
  end

  samples = zeros(sampleCount, 3 + dimensionCount);
  fitness = zeros(sampleCount, 1);

  if ~isnan(nodeCount)
    nodes = zeros(nodeCount, inputCount);
    responses = zeros(nodeCount, outputCount);
  end

  %
  % The initial state of the chain.
  %
  muu     = mu0;
  sigma2u = tau2u;
  sigma2e = tau2e;
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
  fit = computeFitness(qT, muu, sigma2u, sigma2e, z, 0);

  acceptCount = 0;

  for i = 1:sampleCount
    verbose('Metropolis: finished %6.2f%%, accepted %6.2f%%.\n', ...
      i / sampleCount * 100, acceptCount / i * 100);

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
    if i > nodeCount
      %
      % Sample the surrogate.
      %
      [ qT, sigma2q ] = surrogate.evaluate(u);
    else
      %
      % Sample the true model.
      %
      qT = hotspot.compute(Pdyn, timeIndex, leakage, u);
      sigma2q = 0;
    end

    if i <= nodeCount
      nodes(i, :) = u;
      responses(i, :) = qT;

      if i == nodeCount
        surrogate = Test.substitute(c, m, nodes, responses);
      end
    end

    %
    % Compute the fitness, which is proportional to the log-posterior.
    %
    proposedFit = computeFitness( ...
      qT, muu, sigma2u, sigma2e, z, sigma2q);

    %
    % Accept or reject?
    %
    if log(rand) < (proposedFit - fit)
      %
      % Accept!
      %
      sample = [ muu, sigma2u, sigma2e, z' ];
      fit = proposedFit;
      acceptCount = acceptCount + 1;
    end

    %
    % Save the sample.
    %
    samples(i, :) = sample;
    fitness(i) = fit;
  end
end
