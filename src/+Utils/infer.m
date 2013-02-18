function results = infer(c, m)
  verbose = c.verbose;
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  mapping = c.process.constrainMapping(c.observations.dieIndex);
  qmeasT = transpose(m.Tmeas(:));

  model = Utils.forward(c, 'model', 'observed');

  dimensionCount = size(mapping, 2);
  outputCount = length(qmeasT);

  %
  % Set up the likelihood function and prior distributions.
  %
  mu0    = c.prior.mu0;
  sigma0 = c.prior.sigma0;

  nuu  = c.prior.nuu;
  tauu = c.prior.tauu;

  nue  = c.prior.nue;
  taue = c.prior.taue;

  I = 1:dimensionCount;
  if ~c.inference.fixMuu,    I = [ I, dimensionCount + 1 ]; end
  if ~c.inference.fixSigmau, I = [ I, dimensionCount + 2 ]; end
  if ~c.inference.fixSigmae, I = [ I, dimensionCount + 3 ]; end

  etalonSample = [ zeros(dimensionCount + 1, 1); 1; 1 ];

  function result = logPosterior(theta_)
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

  time = struct;

  %
  % Construct a proposal distribution.
  %
  printf('Optimization: in progress using "%s"...\n', ...
    c.optimization.method);

  optimization = Optimization.(c.optimization.method);

  [ theta, covariance, coefficient, time.optimization ] = ...
    Utils.cache(Utils.stamp(c, 'optimization.mat'), ...
      @optimization.perform, etalonSample(I), @logPosterior, c.optimization);

  printf('Optimization: done in %.2f minutes.\n', time.optimization / 60);

  %
  % Assess the constructed proposal distribution.
  %
  if c.proposal.assessmentCount > 0
    printf('Assessment: in progress using %d extra points in each direction...\n', ...
      c.proposal.assessmentCount);

    [ assessment, time.assessment ] = ...
      Utils.cache(Utils.stamp(c, 'assessment.mat'), ...
        @Utils.performProposalAssessment, @logPosterior, theta, ...
        covariance, 'pointCount', c.proposal.assessmentCount);

    printf('Assessment: done in %.2f minutes...\n', time.assessment / 60);
  else
    assessment = [];
    time.assessment = 0;
  end

  proposal = c.proposal;
  proposal.theta = theta;
  proposal.covariance = covariance;
  proposal.coefficient = coefficient;
  proposal.assessment = assessment;

  %
  % Sample!
  %
  metropolis = Metropolis.(c.inference.method);

  printf('Sampling: collecting %d samples...\n', c.inference.sampleCount);

  [ results, time.sampling ] = Utils.cache(Utils.stamp(c, 'sampling.mat'), ...
    @metropolis.perform, @logPosterior, proposal, c.inference);

  printf('Sampling: done in %.2f minutes.\n', time.sampling / 60);

  sampleCount = c.inference.sampleCount;
  assert(sampleCount == size(results.samples, 2));

  %
  % Account for the variable that were excluded from the inference.
  %
  samples = repmat(etalonSample, 1, sampleCount);
  samples(I, :) = results.samples;

  %
  % Denormalize the result!
  %
  samples(end - 2, :) = mu0 + sigma0 * samples(end - 2, :);
  samples(end - 1, :) =         tauu * samples(end - 1, :);
  samples(end - 0, :) =         taue * samples(end - 0, :);

  %
  % Update the results.
  %
  results.time = time;

  results.samples = struct;
  results.samples.z      =     samples(1:(end - 3), :);
  results.samples.muu    =     samples(   end - 2 , :);
  results.samples.sigmau = abs(samples(   end - 1 , :));
  results.samples.sigmae = abs(samples(   end - 0 , :));

  results.proposal = proposal;
end
