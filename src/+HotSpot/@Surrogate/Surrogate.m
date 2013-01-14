classdef Surrogate < HotSpot.Analytic
  methods
    function this = Surrogate(varargin)
      options = Options(varargin{:});
      this = this@HotSpot.Analytic(options);
    end

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
      % Choose only observed dies.
      %
      Lnom = leakage.Lnom;
      Ldev = 0.05 * Lnom;

      I = zeros(1, processorCount * spaceMeasurementCount);
      for i = 1:spaceMeasurementCount
        j = spaceMeasurementIndex(i);
        I(((i - 1) * processorCount + 1):(i * processorCount)) = ...
          ((j - 1) * processorCount + 1):(j * processorCount);
      end

      Lmap = process.mapping(I, :);

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
        @leakage.evaluate, preprocess(rvs)), options);
    end
  end

  methods (Access = 'private')
    function data = evaluate(this, Pdyn, stepIndex, leak, L)
      pointCount = size(L, 2);
      processorCount = size(Pdyn, 1);
      dieCount = size(L, 1) / processorCount;
      stepCount = length(stepIndex);

      data = zeros(pointCount, dieCount * processorCount * stepCount);

      %
      % NOTE: parfor should be used here.
      %
      for k = 1:(pointCount * dieCount)
        i = ceil(k / dieCount);       % point
        j = mod(k - 1, dieCount) + 1; % die

        a = (j - 1) * processorCount * stepCount + 1;
        b = j * processorCount * stepCount;

        c = (j - 1) * processorCount + 1;
        d = j * processorCount;

        data(i, a:b) = this.solve(Pdyn, stepIndex, leak, L(c:d, i));
      end
    end

    function data = solve(this, Pdyn, stepIndex, leak, L)
      processorCount = size(Pdyn, 1);

      E = this.E;
      D = this.D;
      BT = this.BT;
      Tamb = this.ambientTemperature;

      stepCount = length(stepIndex);

      data = zeros(processorCount, stepCount);

      X = zeros(this.nodeCount, 1);
      T = Tamb * ones(processorCount, 1);

      k = 1;
      i = 1;
      while k <= stepCount
        for j = i:stepIndex(k)
          X = E * X + D * (Pdyn(:, j) + leak(L, T));
          T = BT * X + Tamb;
        end
        data(:, k) = T;
        k = k + 1;
        i = j + 1;
      end

      data = data(:);
    end
  end
end
