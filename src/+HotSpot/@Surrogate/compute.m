function surrogate = compute(this, Pdyn, varargin)
  processorCount = size(Pdyn, 1);

  options = Options(varargin{:});

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
  method = options.get('method', 'kriging');
  options = options.get('methodOptions', Options());

  inputCount = process.dimensionCount;
  outputCount = spaceMeasurementCount * processorCount * timeMeasurementCount;

  options.set('inputCount', inputCount);
  options.set('outputCount', outputCount);

  switch lower(method)
  case 'gaussian'
    kernel = Options( ...
      'compute', @correlate, ...
      'parameters', [ 1, 1 ], ...
      'lowerBound', [ 1e-3, 1e-3 ], ...
      'upperBound', [ 2, 10 ]);

    options.set('kernel', kernel);

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

function [ K, dK ] = correlate(x, y, params)
  s = params(1); % Standard deviation
  l = params(2); % Length scale

  n = sum((x - y).^2, 1);
  e = exp(-n / (2 * l^2));
  K = s^2 * e;

  if nargout == 1, return; end % Derivatives?

  dK = [ 2 * s * e; l^(-3) * K .* n ];
end
