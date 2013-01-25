function [ expectation, variance ] = compute(this, z, mu, sigma2)
  Pdyn = this.Pdyn;
  timeIndex = this.timeIndex;
  leakage = this.leakage;

  processorCount = this.processorCount;
  dieCount = this.dieCount;
  pointCount = size(z, 2);

  if isempty(timeIndex)
    timeCount = size(Pdyn, 3);
    timeIndex = 1:timeCount;
  else
    timeCount = length(timeIndex);
  end

  if nargin < 4, sigma2 = 1; end
  if nargin < 3, mu = 0; end

  L = this.Lnom + this.Ldev * (mu + sqrt(sigma2) * this.Zmap * z);
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
