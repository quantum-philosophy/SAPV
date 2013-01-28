function Data = compute(this, L)
  leakage = this.leakage;
  timeIndex = this.timeIndex;
  Pdyn = this.Pdyn;

  processorCount = this.processorCount;
  dieCount = this.dieCount;
  pointCount = size(L, 2);

  if isempty(timeIndex)
    timeCount = size(Pdyn, 3);
    timeIndex = 1:timeCount;
  else
    timeCount = length(timeIndex);
  end

  L = reshape(L, [ processorCount, dieCount, pointCount ]);

  E = this.E;
  D = this.D;
  BT = this.BT;
  Tamb = this.ambientTemperature;

  Data = zeros(pointCount, processorCount * timeCount * dieCount);

  parfor p = 1:pointCount
    l = L(:, :, p);

    data = zeros(processorCount, timeCount, dieCount);

    X = zeros(this.nodeCount, dieCount);
    T = Tamb * ones(processorCount, dieCount);

    k = 1;
    i = 1;
    while k <= timeCount
      for j = i:timeIndex(k)
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
