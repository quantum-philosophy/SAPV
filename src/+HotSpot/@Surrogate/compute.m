function surrogate = compute(this, Pdyn, varargin)
  processorCount = size(Pdyn, 1);

  options = Options(varargin{:});

  method = options.get('method', 'kriging');

  leakage = options.leakage;
  process = options.process;

  %
  % Spatial and temporal indices.
  %
  spaceMeasurementIndex = options.spaceMeasurementIndex;
  spaceMeasurementCount = length(spaceMeasurementIndex);

  timeMeasurementIndex = options.timeMeasurementIndex;
  timeMeasurementCount = length(timeMeasurementIndex);

  %
  % Leakage.
  %
  Lnom = options.Lnom;
  Ldev = options.Ldev;
  Lmap = process.constrainMapping(spaceMeasurementIndex);

  %
  % Configure the surrogate construction algorithm.
  %
  if options.has('surrogateOptions')
    options = options.surrogateOptions;
  else
    options = Options();
  end

  inputCount = process.dimensionCount;
  outputCount = spaceMeasurementCount * processorCount * timeMeasurementCount;

  options.set('inputCount', inputCount);
  options.set('outputCount', outputCount);

  function [ k, dk ] = kernel(s, t, l)
    n = sum((s - t).^2, 1) / 2;
    k = exp(-n / l^2);
    if nargout == 1, return; end
    dk = k .* l^(-3) .* n;
  end

  switch method
  case 'gaussian'
    options.set('kernel', @kernel);
    options.set('parameters', 1);
    options.set('lowerBound', 1e-3);
    options.set('upperBound', 10);

    surrogate = Regression.GaussianProcess( ...
      'target', @(u) this.evaluate(Pdyn, timeMeasurementIndex, leakage, ...
        Lnom + Ldev * Lmap * norminv(u).'), options);
  case 'kriging'
    options.set('parameters', ones(1, inputCount));
    options.set('lowerBound', ones(1, inputCount) * 1e-3);
    options.set('upperBound', ones(1, inputCount) * 10);

    surrogate = Regression.Kriging( ...
      'target', @(u) this.evaluate(Pdyn, timeMeasurementIndex, leakage, ...
        Lnom + Ldev * Lmap * norminv(u).'), options);
  case 'asgc'
    %
    % NOTE: Not actually a good idea, but here we are trying to prevent
    % unrealistic values like negatives and infinities. Applies only
    % to the ASGC algorithm as it is based on uniform distributions.
    %
    sigma = 1;
    offset = normcdf(-3 * sigma);

    surrogate = ASGC(@(u) this.evaluate(Pdyn, timeMeasurementIndex, leakage, ...
      Lnom + Ldev * Lmap * norminv(offset + (1 - 2 * offset) * u).'), options);
  otherwise
    assert(false);
  end
end
