function data = compute(this, L)
  [ inputCount, pointCount ] = size(L);
  assert(pointCount == 1);

  leak = this.leakage.evaluate;

  nodeCount = this.nodeCount;
  dieCount = this.dieCount;
  timeIndex = this.timeIndex;
  timeCount = length(timeIndex);
  processorCount = this.processorCount;

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

  L = reshape(L, [ processorCount, dieCount ]);

  E = this.E;
  D = this.D;
  BT = this.BT;
  Tamb = this.ambientTemperature;

  data = zeros(processorCount, timeCount, dieCount);

  X = zeros(nodeCount, dieCount);
  T = Tamb * ones(processorCount, dieCount);

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
