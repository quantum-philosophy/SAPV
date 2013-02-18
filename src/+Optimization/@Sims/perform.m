function [ theta, covariance, coefficient ] = ...
  perform(this, theta, logPosterior, varargin)

  options = Options(varargin{:});

  settings = Options;
  settings.verbose = options.get('verbose', false);
  settings.maximalFunctionCount = options.maximalStepCount;
  settings.stallThreshold = options.stallThreshold;

  [ ~, theta, ~, covariance ] = csminwel( ...
    @(theta_) -feval(logPosterior, theta_), theta, ...
    1e-4 * eye(length(theta)), [], settings);

  %
  % Now, we have the inverse Hessian matrix at a posterior mode,
  % and we need to turn into a Cholesky-like multiplier.
  %
  coefficient = chol(covariance, 'lower');
end
