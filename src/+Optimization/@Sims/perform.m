function [ theta, covariance, coefficient ] = ...
  perform(this, theta, logPosterior, varargin)

  options = Options(varargin{:});
  verbose = options.get('verbose', false);

  settings = Options;
  settings.verbose = false;
  settings.maximalFunctionCount = options.maximalStepCount;
  settings.stallThreshold = options.stallThreshold;

  [ ~, theta, ~, covariance, stepCount, functionCount ] = csminwel( ...
    @(theta_) -feval(logPosterior, theta_), theta, ...
    1e-4 * eye(length(theta)), [], settings);

  %
  % Now, we have the inverse Hessian matrix at a posterior mode,
  % and we need to turn into a Cholesky-like multiplier.
  %
  coefficient = chol(covariance, 'lower');

  if ~verbose, return; end

  fprintf('Optimization:\n');
  fprintf('  # of iterations:  %d\n', stepCount);
  fprintf('  # of evaluations: %d\n', functionCount);
end
