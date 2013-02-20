function results = perform(this, logPosteriorFunction, proposal, varargin)
  options = Options(varargin{:});

  verbose = options.get('verbose', false);
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  sampleCount = options.sampleCount;
  dimensionCount = length(proposal.theta);

  proposedTheta = this.propose(NaN, proposal, sampleCount);
  proposedLogPosterior = feval(logPosteriorFunction, proposedTheta);

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
