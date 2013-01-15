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
        leakage, preprocess(rvs)), options);
    end
  end

  methods (Access = 'private')
    function Data = evaluate(this, Pdyn, stepIndex, leakage, L)
      pointCount = size(L, 2);
      [ processorCount, powerStepCount ] = size(Pdyn);
      dieCount = size(L, 1) / processorCount;
      stepCount = length(stepIndex);
      nodeCount = this.nodeCount;

      E = this.E;
      D = this.D;
      BT = this.BT;
      Tamb = this.ambientTemperature;

      %
      % Replicate the power profile cover all the dies at once.
      %
      Pdyn = reshape(kron(Pdyn, ones(1, dieCount)), ...
        [ processorCount, dieCount, powerStepCount ]);

      %
      % For convenience and efficiency, reshape the uncertain parameter.
      %
      L = reshape(L, [ processorCount, dieCount, pointCount ]);

      %
      % Allocate space for all the data that we are going to compute.
      %
      Data = zeros(pointCount, dieCount * processorCount * stepCount);

      %
      % NOTE: parfor should be used here to fill in `Data'.
      %
      for p = 1:pointCount
        l = L(:, :, p);

        data = zeros(processorCount, stepCount, dieCount);

        X = zeros(nodeCount, dieCount);
        T = Tamb * ones(processorCount, dieCount);

        k = 1;
        i = 1;
        while k <= stepCount
          for j = i:stepIndex(k)
            X = E * X + D * (Pdyn(:, :, j) + leakage.evaluate(l, T));
            T = BT * X + Tamb;
          end
          data(:, k, :) = T;
          k = k + 1;
          i = j + 1;
        end

        Data(p, :) = data(:);
      end
    end
  end
end
