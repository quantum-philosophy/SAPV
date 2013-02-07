function analyze(c, m, results, printf)
  if nargin < 4, printf = @fprintf; end
  analyzePerformance (c, m, results, printf);
  analyzeCorrelations(c, m, results, printf);
end

function analyzePerformance(c, m, results, printf)
  MSE = Error.computeMSE    (m.u * 1e9, results.u * 1e9);
  RMSE = Error.computeRMSE  (m.u * 1e9, results.u * 1e9);
  NRMSE = Error.computeNRMSE(m.u, results.u);

  printf('Performance:\n');
  printf('%10s: %10.2f %s\n', 'Time', results.time / 60, 'm');
  printf('%10s: %10.2e %s\n', 'MSE', MSE, 'nm^2');
  printf('%10s: %10.2e %s\n', 'RMSE', RMSE, 'nm');
  printf('%10s: %10.2f %s\n', 'NRMSE', NRMSE * 100, '%');
  printf('\n');
end

function analyzeCorrelations(c, m, results, printf)
  extremeCorrelationBound = 0.5;

  [ S, C ] = covarianceToCorrelation(results.covariance);
  C = tril(C, -1);
  [ I, J ] = find(abs(C) > extremeCorrelationBound);

  if isempty(I), return; end

  count = size(C, 1);

  printf('Highly correlated (> %.2f) pairs (%d out of %d):\n', ...
    extremeCorrelationBound, length(I), count * (count - 1) / 2);
  for i = 1:length(I);
    printf('Corr(%5d, %5d) = %10.2f\n', J(i), I(i), C(I(i), J(i)));
  end
  printf('\n');
end

function [ S, C ] = covarianceToCorrelation(K)
  S = sqrt(diag(K))';
  C = diag(1 ./ S) * K * diag(1 ./ S);
end
