function results = perform(this, logPosteriorFunction, proposal, varargin)
  options = Options(varargin{:});
  verbose = options.get('verbose', false);

  sampleCount = options.sampleCount;
  dimensionCount = length(proposal.theta);

  proposedTheta = this.propose(NaN, proposal, sampleCount);
  proposedLogPosterior = zeros(1, sampleCount);

  parfor i = 1:sampleCount
    proposedLogPosterior(i) = feval(logPosteriorFunction, proposedTheta(:, i));

    if verbose && mod(i, 1e2) == 0
      fprintf('Sampling: done %6.2f%% (out of order).\n', 100 * i / sampleCount);
    end
  end

  currentTheta = proposal.theta;
  currentLogPosterior = feval(logPosteriorFunction, proposal.theta);

  samples = zeros(dimensionCount, sampleCount);
  logPosterior = zeros(1, sampleCount);
  acceptance = false(1, sampleCount);

  logRand = log(rand(1, sampleCount));

  for i = 1:sampleCount
    if logRand(i) < (proposedLogPosterior(i) - currentLogPosterior)
      currentTheta = proposedTheta(:, i);
      currentLogPosterior = proposedLogPosterior(i);
      acceptance(i) = true;
    end

    samples(:, i) = currentTheta;
    logPosterior(i) = currentLogPosterior;
  end

  results.samples = samples;
  results.logPosterior = logPosterior;
  results.acceptance = acceptance;
end
