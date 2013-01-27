function [ expectation, variance ] = compute(this, z, mu, sigma2)
  timeIndex = this.timeIndex;

  leakage = this.leakage;
  process = this.process;

  Pdyn = this.Pdyn;

  processorCount = this.processorCount;
  dieCount = this.dieCount;
  pointCount = size(z, 2);

  if isempty(timeIndex)
    timeCount = size(Pdyn, 3);
    timeIndex = 1:timeCount;
  else
    timeCount = length(timeIndex);
  end

  if nargin < 3, mu = process.nominal; end
  if nargin < 4, sigma2 = process.deviation^2; end

  L = mu + sqrt(sigma2) * this.mapping * z;
  L = reshape(L, [ processorCount, dieCount, pointCount ]);

  E = this.E;
  D = this.D;
  BT = this.BT;
  Tamb = this.ambientTemperature;

  expectation = zeros(pointCount, processorCount * timeCount * dieCount);

  for p = 1:pointCount
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

    expectation(p, :) = data(:);
  end

  if nargout == 1, return; end

  variance = 0;
end
