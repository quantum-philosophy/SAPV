function results = sample(this)
  verbose = this.verbose;
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  mapping = this.mapping;
  inference = this.inference;
  qmeasT = this.qmeasT;
  model = this.model;

  dimensionCount = size(mapping, 2);
  outputCount = length(qmeasT);
  sampleCount = inference.sampleCount;

  %
  % The priors.
  %
  mu0    = inference.mu0;
  sigma0 = inference.sigma0;

  nuu  = inference.nuu;
  tauu = inference.tauu;

  nue  = inference.nue;
  taue = inference.taue;

  I = 1:dimensionCount;
  if ~inference.fixMuu,    I = [ I, dimensionCount + 1 ]; end
  if ~inference.fixSigmau, I = [ I, dimensionCount + 2 ]; end
  if ~inference.fixSigmae, I = [ I, dimensionCount + 3 ]; end

  etalonSample = [ zeros(dimensionCount + 1, 1); 1; 1 ];

  %
  % NOTE: The inference we do is for the normalized parameters.
  %
  function result = computeFitness(theta_)
    sample_    = etalonSample;
    sample_(I) = theta_;

    z_       = sample_(1:(end - 3));
    muun_    = sample_(   end - 2);
    sigmaun_ = sample_(   end - 1);
    sigmaen_ = sample_(   end - 0);

    node_ = (mu0 + sigma0 * muun_) + tauu * sigmaun_ * mapping * z_;
    qT_ = model.compute(node_);

    muu_     = mu0 + sigma0 * muun_;
    sigma2u_ = (tauu * sigmaun_)^2;
    sigma2e_ = (taue * sigmaen_)^2;

    result = ...
      - (outputCount / 2) * log(sigma2e_) ...
      - sum((qmeasT - qT_).^2) / sigma2e_ / 2 ...
      ...
      - sum(z_.^2) / 2 ...
      ...
      - (muu_ - mu0)^2 / sigma0^2 / 2 ...
      ...
      - (1 + nuu / 2) * log(sigma2u_) ...
      - nuu * tauu^2 / sigma2u_ / 2 ...
      ...
      - (1 + nue / 2) * log(sigma2e_) ...
      - nue * taue^2 / sigma2e_ / 2;
  end

  %
  % Construct a proposal distribution.
  %
  printf('Proposal: in progress using "%s"...\n', ...
    inference.optimization.method);

  optimizationTime = tic;
  proposal = this.optimize(etalonSample(I), @computeFitness);
  optimizationTime = toc(optimizationTime);

  printf('Proposal: done in %.2f minutes.\n', optimizationTime / 60);

  %
  % Initial values.
  %
  samples = repmat(etalonSample', sampleCount, 1);
  fitness = zeros(sampleCount, 1);
  acceptance = false(1, sampleCount);

  currentFitness = -Inf;
  currentTheta = proposal.theta;
  proposedTheta = currentTheta;

  samplingTime = tic;

  for i = 1:sampleCount
    %
    % Compute the fitness, which is proportional to the log-posterior.
    %
    proposedFitness = computeFitness(proposedTheta);

    %
    % Accept or reject?
    %
    if log(rand) < (proposedFitness - currentFitness)
      %
      % Accept!
      %
      currentTheta = proposedTheta;
      currentFitness = proposedFitness;
      acceptance(i) = true;
    end

    %
    % Save the sample.
    %
    samples(i, I) = currentTheta;
    fitness(i) = currentFitness;

    %
    % Print the progress so far.
    %
    if verbose && mod(i, 1e2) == 0
      finished = 100 * i / sampleCount;
      accepted = 100 * mean(acceptance(1:i));
      rate     = 100 * mean(acceptance((i - 1e2 + 1):i));
      printf('Metropolis: done %6.2f%% (%6d), accepted %5.2f%%, rate %5.2f%%, fitness %10.2f.\n', ...
        finished, i, accepted, rate, currentFitness);
    end

    %
    % Propose a new value for the parameters!
    %
    proposedTheta = this.propose(currentTheta, proposal);
  end

  samplingTime = toc(samplingTime);

  printf('Metropolis: done in %.2f minutes.\n', samplingTime / 60);

  %
  % Do not forget to denormalize the result!
  %
  samples(:, end - 2) = mu0 + sigma0 * samples(:, end - 2);
  samples(:, end - 1) =         tauu * samples(:, end - 1);
  samples(:, end - 0) =         taue * samples(:, end - 0);

  %
  % Save the result.
  %
  results.time = struct;
  results.time.optimization = optimizationTime;
  results.time.sampling     = samplingTime;

  results.proposal = proposal;

  results.samples = struct;
  results.samples.count  = sampleCount;
  results.samples.z      =     samples(:,  1:(end - 3))';
  results.samples.muu    =     samples(:,     end - 2)';
  results.samples.sigmau = abs(samples(:,     end - 1))';
  results.samples.sigmae = abs(samples(:,     end - 0))';

  results.fitness    = fitness;
  results.acceptance = acceptance;
end
