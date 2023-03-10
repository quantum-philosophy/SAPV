function results = perform(this, logPosteriorFunction, proposal, varargin)
  options = Options(varargin{:});
  verbose = options.get('verbose', false);

  sampleCount = options.sampleCount;
  dimensionCount = length(proposal.theta);

  currentTheta = proposal.theta;
  currentLogPosterior = feval(logPosteriorFunction, proposal.theta);

  samples = zeros(dimensionCount, sampleCount);
  logPosterior = zeros(1, sampleCount);
  acceptance = false(1, sampleCount);

  logRand = log(rand(1, sampleCount));

  for i = 1:sampleCount
    proposedTheta = this.propose(currentTheta, proposal);
    proposedLogPosterior = feval(logPosteriorFunction, proposedTheta);

    if logRand(i) < (proposedLogPosterior - currentLogPosterior)
      currentTheta = proposedTheta;
      currentLogPosterior = proposedLogPosterior;
      acceptance(i) = true;
    end

    samples(:, i) = currentTheta;
    logPosterior(i) = currentLogPosterior;

    if verbose && mod(i, 1e2) == 0
      finished = 100 * i / sampleCount;
      accepted = 100 * mean(acceptance(1:i));
      rate     = 100 * mean(acceptance((i - 1e2 + 1):i));

      fprintf('Sampling: done %6.2f%%, accepted %5.2f%%, rate %5.2f%%.\n', ...
        finished, accepted, rate);
    end
  end

  results.samples = samples;
  results.logPosterior = logPosterior;
  results.acceptance = acceptance;
end
