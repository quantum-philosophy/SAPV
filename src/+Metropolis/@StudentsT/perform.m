function results = perform(this, logPosteriorFunction, proposal, varargin)
  options = Options(varargin{:});

  verbose = options.get('verbose', false);
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  sampleCount = options.sampleCount;

  %
  % Should we start from the value found by the optimization?
  % It typically blocks the sampling procedure for about first 1000
  % samples or so.
  %
  % samples = [ proposal.theta, this.propose(NaN, proposal, sampleCount - 1) ];
  %
  samples = this.propose(NaN, proposal, sampleCount);
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
