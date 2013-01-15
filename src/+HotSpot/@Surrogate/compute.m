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
  if options.has('surrogateOptions')
    options = options.surrogateOptions;
  else
    options = Options();
  end

  options.set('inputCount', process.dimensionCount);
  options.set('outputCount', ...
    spaceMeasurementCount * processorCount  * timeMeasurementCount);

  %
  % NOTE: Not actually a good idea, but here we are trying to prevent
  % unrealistic values like negatives and infinities. Applies only
  % to the ASGC algorithm as it is based on uniform distributions.
  %
  sigma = 1;
  offset = normcdf(-3 * sigma);

  function rvs = preprocess(rvs)
    rvs = offset + (1 - 2 * offset) * rvs;
    rvs = Lnom + Ldev * Lmap * norminv(rvs).';
  end

  surrogate = ASGC(@(rvs) this.evaluate(Pdyn, timeMeasurementIndex, ...
    leakage, preprocess(rvs)), options);
end
