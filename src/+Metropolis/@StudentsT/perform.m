function results = perform(this, logPosteriorFunction, proposal, varargin)
  options = Options(varargin{:});

  verbose = options.get('verbose', false);
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  sampleCount = options.sampleCount;

  samples = [ proposal.theta, this.propose(NaN, proposal, sampleCount - 1) ];
  logPosterior = feval(logPosteriorFunction, samples);
  acceptance = true(1, sampleCount);

  logRand = log(rand(1, sampleCount));

  for i = 2:sampleCount % The first one is always accepted.
    if logRand(i) > (logPosterior(i) - logPosterior(i - 1))
      acceptance(i) = false;
      samples(:, i) = samples(:, i - 1);
      logPosterior(i) = logPosterior(i - 1);
    end
  end

  results.samples = samples;
  results.logPosterior = logPosterior;
  results.acceptance = acceptance;
end
