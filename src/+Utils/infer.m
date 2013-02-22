function results = infer(c, m)
  verbose = c.verbose;
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  mapping = c.process.constrainMapping(c.observations.dieIndex);
  qmeasT = transpose(m.Tmeas(:));

  model = Utils.forward(c, 'model', 'observed');

  [ inputCount, dimensionCount ] = size(mapping);
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
    count_ = size(theta_, 2);

    if count_ == 1
      sample_    = etalonSample;
      sample_(I) = theta_;

      z_       = sample_(1:(end - 3));
      muun_    = sample_(   end - 2 );
      sigmaun_ = sample_(   end - 1 );
      sigmaen_ = sample_(   end - 0 );

      node_ = (mu0 + sigma0 * muun_) + tauu  * sigmaun_ * mapping * z_;
      deltaT_ = qmeasT - reshape(model.compute(node_), 1, []);
    else
      sample_       = repmat(etalonSample, [ 1, count_ ]);
      sample_(I, :) = theta_;

      z_       = sample_(1:(end - 3), :);
      muun_    = sample_(   end - 2 , :);
      sigmaun_ = sample_(   end - 1 , :);
      sigmaen_ = sample_(   end - 0 , :);

      muun__    = repmat(muun_,    [ inputCount, 1 ]);
      sigmaun__ = repmat(sigmaun_, [ inputCount, 1 ]);

      node_ = (mu0 + sigma0 * muun__) + tauu * sigmaun__ .* (mapping * z_);
      deltaT_ = repmat(qmeasT, [ count_, 1 ]) - reshape(model.compute(node_), [], count_).';
    end

    muu_     = mu0 + sigma0 * muun_;
    sigma2u_ = (tauu * sigmaun_).^2;
    sigma2e_ = (taue * sigmaen_).^2;

    result = ...
      - (outputCount / 2) * log(sigma2e_) ...
      - sum(deltaT_.^2, 2)' ./ sigma2e_ / 2 ...
      ...
      - sum(z_.^2, 1) / 2 ...
      ...
      - (muu_ - mu0).^2 / sigma0^2 / 2 ...
      ...
      - (1 + nuu / 2) * log(sigma2u_) ...
      - nuu * tauu^2 ./ sigma2u_ / 2 ...
      ...
      - (1 + nue / 2) * log(sigma2e_) ...
      - nue * taue^2 ./ sigma2e_ / 2;
  end

  time = struct;

  %
  % Construct a proposal distribution.
  %
  optimization = Optimization.(c.optimization.method);

  stamp = Utils.stamp(c, 'optimization', c.observations, ...
    c.inference, c.prior, c.optimization, qmeasT);

  printf('Optimization: in progress using "%s"...\n', ...
    c.optimization.method);

  [ theta, covariance, coefficient, time.optimization ] = ...
    Utils.cache(stamp, @optimization.perform, ...
      etalonSample(I), @logPosterior, c.optimization);

  printf('Optimization: done in %.2f minutes.\n', time.optimization / 60);

  %
  % Assess the constructed proposal distribution.
  %
  if c.assessment.pointCount > 0
    stamp = Utils.stamp(c, 'assessment', c.observations, ...
      c.inference, c.prior, c.optimization, c.assessment, qmeasT);

    printf('Assessment: in progress using %d extra points in each direction...\n', ...
      c.assessment.pointCount);

    [ assessment, time.assessment ] = ...
      Utils.cache(stamp, @Utils.performProposalAssessment, ...
        @logPosterior, theta, covariance, c.assessment);

    printf('Assessment: done in %.2f minutes.\n', time.assessment / 60);
  else
    assessment = [];
    time.assessment = 0;
  end

  proposal = Options(c.proposal);
  proposal.theta = theta;
  proposal.covariance = covariance;
  proposal.coefficient = coefficient;
  proposal.assessment = assessment;

  %
  % Sample!
  %
  metropolis = Metropolis.(c.inference.method);

  stamp = Utils.stamp(c, 'sampling', c, qmeasT);

  printf('Sampling: collecting %d samples using "%s"...\n', ...
    c.inference.sampleCount, c.inference.method);

  [ results, time.sampling ] = Utils.cache(stamp, ...
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
