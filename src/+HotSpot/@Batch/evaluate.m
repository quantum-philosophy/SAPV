function Data = evaluate(this, Pdyn, stepIndex, leakage, U)
  [ processorCount, powerStepCount ] = size(Pdyn);
  pointCount = size(U, 2);
  dieCount = size(U, 1) / processorCount;
  stepCount = length(stepIndex);
  nodeCount = this.nodeCount;

  if stepCount == 0, stepCount = powerStepCount; end

  E = this.E;
  D = this.D;
  BT = this.BT;
  Tamb = this.ambientTemperature;

  %
  % Replicate the power profile to cover all the dies at once.
  %
  Pdyn = reshape(kron(Pdyn, ones(1, dieCount)), ...
    [ processorCount, dieCount, powerStepCount ]);

  %
  % For convenience and efficiency, reshape the uncertain parameters.
  %
  U = reshape(U, [ processorCount, dieCount, pointCount ]);

  %
  % Allocate space for all the data that we are going to compute.
  %
  Data = zeros(pointCount, dieCount * processorCount * stepCount);

  if stepCount < powerStepCount
    %
    % Sparse calculation.
    %
    for p = 1:pointCount
      u = U(:, :, p);

      data = zeros(processorCount, stepCount, dieCount);

      X = zeros(nodeCount, dieCount);
      T = Tamb * ones(processorCount, dieCount);

      k = 1;
      i = 1;
      while k <= stepCount
        for j = i:stepIndex(k)
          X = E * X + D * (Pdyn(:, :, j) + leakage.evaluate(u, T));
          T = BT * X + Tamb;
        end
        data(:, k, :) = T;
        k = k + 1;
        i = j + 1;
      end

      Data(p, :) = data(:);
    end
  elseif stepCount == powerStepCount
    %
    % Dense calculation.
    %
    for p = 1:pointCount
      u = U(:, :, p);

      data = zeros(processorCount, stepCount, dieCount);

      X = zeros(nodeCount, dieCount);
      T = Tamb * ones(processorCount, dieCount);

      for i = 1:stepCount
        X = E * X + D * (Pdyn(:, :, i) + leakage.evaluate(u, T));
        T = BT * X + Tamb;
        data(:, i, :) = T;
      end

      Data(p, :) = data(:);
    end
  else
    assert(false);
  end
end
