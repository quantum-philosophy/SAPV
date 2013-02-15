function results = optimize(this, theta, computeFitness)
  verbose = this.verbose;
  printf = @fprintf;
  if ~verbose, printf = @(varargin) []; end

  inference = this.inference;

  switch lower(inference.optimization.method)
  case 'none'
    %
    % No optimization.
    %
    covariance = eye(length(theta));
    coefficient = covariance;
  case 'csminwel'
    %
    % Using the library suggested by Mattias.
    %
    options = Options;
    options.verbose = verbose;
    options.maximalFunctionCount = inference.optimization.maximalStepCount;
    options.stallThreshold = inference.optimization.stallThreshold;

    [ ~, theta, ~, covariance ] = csminwel( ...
      @(theta_) -computeFitness(theta_), theta, ...
      1e-4 * eye(length(theta)), [], options);

    %
    % Now, we have the inverse Hessian matrix at a posterior mode,
    % and we need to turn into a Cholesky-like multiplier.
    %
    coefficient = chol(covariance, 'lower');
  case 'fminunc'
    %
    % Using MATLAB's facilities.
    %
    options.MaxFunEvals = inference.optimization.maximalStepCount;
    options.TolFun = inference.optimization.stallThreshold;
    options.LargeScale = 'off';
    if verbose, options.Display = 'iter';
    else options.Display = 'off'; end

    [ theta, ~, ~, ~, ~, hessian ] = fminunc( ...
      @(theta_) -computeFitness(theta_), theta, options);

    %
    % Now, we have the Hessian matrix at a posterior mode, and
    % we need to invert it and turn into a Cholesky-like multiplier.
    %
    [ U, L ] = eig(hessian);
    L = diag(L);

    covariance = U * diag(1 ./ abs(L)) * U';
    coefficient = U * diag(1 ./ sqrt(abs(L)));

    printf('Proposal: %d out of %d eigenvalues are negative.\n', ...
      sum(L < 0), length(L));
  otherwise
    assert(false);
  end

  %
  % Assessment of the quality of the constructed proposal distribution.
  %
  if inference.proposal.assessmentCount > 0
    printf('Proposal: assessment using %d extra points in each direction...\n', ...
      inference.proposal.assessmentCount);
    assessment = Utils.performProposalAssessment( ...
      computeFitness, theta, covariance, ...
      'pointCount', inference.proposal.assessmentCount);
  else
    assessment = [];
  end

  results.theta = theta;
  results.covariance = covariance;
  results.coefficient = coefficient;
  results.assessment = assessment;
end
