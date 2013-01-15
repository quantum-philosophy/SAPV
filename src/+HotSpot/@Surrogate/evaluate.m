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
  % Replicate the power profile to cover all the dies at once.
  %
  Pdyn = reshape(kron(Pdyn, ones(1, dieCount)), ...
    [ processorCount, dieCount, powerStepCount ]);

  %
  % For convenience and efficiency, reshape the uncertain parameters.
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
