function results = perform(this, logPosteriorFunction, proposal, varargin)
  options = Options(varargin{:});

  verbose = options.get('verbose', false);
  sampleCount = options.sampleCount;

  %
  % Initial values.
  %
  currentLogPosterior = -Inf;
  currentTheta = proposal.theta;
  proposedTheta = currentTheta;

  samples = zeros(length(currentTheta), sampleCount);
  logPosterior = zeros(1, sampleCount);
  acceptance = false(1, sampleCount);

  for i = 1:sampleCount
    %
    % Compute the log-posterior (in fact, something that is proportional to it).
    %
    proposedLogPosterior = feval(logPosteriorFunction, proposedTheta);

    %
    % Accept or reject?
    %
    if log(rand) < (proposedLogPosterior - currentLogPosterior)
      %
      % Accept!
      %
      currentTheta = proposedTheta;
      currentLogPosterior = proposedLogPosterior;
      acceptance(i) = true;
    end

    %
    % Save the sample.
    %
    samples(:, i) = currentTheta;
    logPosterior(i) = currentLogPosterior;

    %
    % Print the progress.
    %
    if verbose && mod(i, 1e2) == 0
      finished = 100 * i / sampleCount;
      accepted = 100 * mean(acceptance(1:i));
      rate     = 100 * mean(acceptance((i - 1e2 + 1):i));
      fprintf('Sampling: done %6.2f%%, accepted %5.2f%%, rate %5.2f%%, log-posterior %10.2f.\n', ...
        finished, accepted, rate, currentLogPosterior);
    end

    %
    % Propose a new value for the parameters!
    %
    proposedTheta = this.propose(currentTheta, proposal);
  end

  results.samples = samples;
  results.logPosterior = logPosterior;
  results.acceptance = acceptance;
end
