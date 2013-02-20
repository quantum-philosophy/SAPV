function [ theta, covariance, coefficient ] = perform(this, theta, logPosterior, varargin)
  options = Options(varargin{:});
  verbose = options.get('verbose', false);

  settings.MaxFunEvals = options.maximalStepCount;
  settings.TolFun = options.stallThreshold;
  settings.LargeScale = 'off';
  settings.Display = 'off';

  [ theta, ~, ~, output, ~, hessian ] = fminunc( ...
    @(theta_) -feval(logPosterior, theta_), theta, settings);

  %
  % Now, we have the Hessian matrix at a posterior mode, and
  % we need to invert it and turn into a Cholesky-like multiplier.
  %
  [ U, L ] = eig(hessian);
  L = diag(L);

  covariance = U * diag(1 ./ abs(L)) * U';
  coefficient = U * diag(1 ./ sqrt(abs(L)));

  if ~verbose, return; end

  fprintf('Optimization:\n');
  fprintf('  Algorithm:              %s\n', output.algorithm);
  fprintf('  # of iterations:        %d\n', output.iterations);
  fprintf('  # of evaluations:       %d\n', output.funcCount);
  fprintf('  # negative eigenvalues: %d\n', sum(L < 0));
  fprintf('  Exit message:\n<<<\n%s\n>>>\n', output.message);
end
