function data = compute(this, L)
  leak = this.leakage.evaluate;

  dieCount = this.dieCount;
  timeIndex = this.timeIndex;
  timeCount = length(timeIndex);
  processorCount = this.processorCount;

  [ inputCount, pointCount ] = size(L);
  assert(inputCount == processorCount * dieCount);

  %
  % The meaning of each dimension of the dynamic power
  % profile is as follows:
  %
  %   * 1 - processors,
  %   * 2 - dies,
  %   * 3 - time.
  %
  Pdyn = this.Pdyn;

  %
  % In case of several samples, the second dimension
  % should be extended accordingly.
  %
  if pointCount > 1
    Pdyn = repmat(Pdyn, [ 1, pointCount, 1 ]);
  end

  L = reshape(L, processorCount, []);

  E = this.E;
  D = this.D;
  BT = this.BT;
  Tamb = this.ambientTemperature;

  data = zeros(processorCount, timeCount, dieCount * pointCount);

  X = zeros(this.nodeCount, dieCount * pointCount);
  T = Tamb * ones(processorCount, dieCount * pointCount);

  k = 1;
  i = 1;
  while k <= timeCount
    for j = i:timeIndex(k)
      X = E * X + D * (Pdyn(:, :, j) + leak(L, T));
      T = BT * X + Tamb;
    end
    data(:, k, :) = T;
    k = k + 1;
    i = j + 1;
  end
end
