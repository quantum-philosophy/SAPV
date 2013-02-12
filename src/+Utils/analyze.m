function analyze(c, m, results)
  fprintf('Computational time: %.2f minutes.\n', results.time / 60);
  fprintf('\n');

  %
  % The u's.
  %
  fprintf('The quantity of interest (u):\n');

  MSE   = Error.computeMSE  (m.u * 1e9, results.mean.u * 1e9);
  RMSE  = Error.computeRMSE (m.u * 1e9, results.mean.u * 1e9);
  NRMSE = Error.computeNRMSE(m.u, results.mean.u);

  fprintf('%7s: %10.2e %s\n', 'MSE', MSE, 'nm^2');
  fprintf('%7s: %10.2e %s\n', 'RMSE', RMSE, 'nm');
  fprintf('%7s: %10.2f %s\n', 'NRMSE', NRMSE * 100, '%');
  fprintf('\n');

  %
  % The z's.
  %
  fprintf('The dummy variables (z):\n');
  compare(m.z, results.mean.z, results.deviation.z);
  fprintf('\n');

  %
  % The rest.
  %
  if ~c.inference.fixMuu
    fprintf('The mean of the QoI (mu_u, nm):\n');
    compare(c.process.nominal, results.mean.muu, ...
      results.deviation.muu, 1e9);
    fprintf('\n');
  end

  if ~c.inference.fixSigmau
    fprintf('The deviation of the QoI (sigma_u, nm):\n');
    compare(c.process.deviation, results.mean.sigmau, ...
      results.deviation.sigmau, 1e9);
    fprintf('\n');
  end

  if ~c.inference.fixSigmae
    fprintf('The deviation of the noise (sigma_e):\n');
    compare(c.observations.deviation, results.mean.sigmae, ...
      results.deviation.sigmae);
    fprintf('\n');
  end

  %
  % The proposal distribution.
  %
  extremeCorrelationBound = 0.5;

  [ S, C ] = covarianceToCorrelation(results.covariance);
  C = tril(C, -1);
  [ I, J ] = find(abs(C) > extremeCorrelationBound);

  if ~isempty(I)
    count = size(C, 1);

    fprintf('Highly correlated (> %.2f) pairs of the proposal distribution:\n', ...
      extremeCorrelationBound);

    fprintf('%5s %5s %15s\n', 'No', 'No', 'Correlation');
    for i = 1:length(I);
      fprintf('%5d %5d %15.4f\n', J(i), I(i), C(I(i), J(i)));
    end
    fprintf('Total: %d out of %d distinct pairs.\n', length(I), count * (count - 1) / 2);

    fprintf('\n');
  end
end

function compare(true, inferred, deviation, scale)
  if nargin < 4, scale = 1; end

  true      = scale * true;
  inferred  = scale * inferred;
  deviation = scale * deviation;

  delta = true - inferred;
  if isscalar(true)
    fprintf('%10s %10s %10s %10s\n', ...
      'True', 'Inferred', 'Deviation', 'Error');
    fprintf('%10.4f %10.4f %10.4f %10.4f (%7.2f%%)\n', ...
      true, inferred, deviation, delta, ...
      abs(delta / true * 100));
  else
    fprintf('%5s %10s %10s %10s %10s\n', ....
      'No', 'True', 'Inferred', 'Deviation', 'Error');
    for i = 1:length(true)
      fprintf('%5d %10.4f %10.4f %10.4f %10.4f (%7.2f%%)\n', ...
        i, true(i), inferred(i), deviation(i), delta(i), ...
        abs(delta(i) / true(i) * 100));
    end
  end
end

function [ S, C ] = covarianceToCorrelation(K)
  S = sqrt(diag(K))';
  C = diag(1 ./ S) * K * diag(1 ./ S);
end
