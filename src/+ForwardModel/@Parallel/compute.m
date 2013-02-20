function data = compute(this, L)
  [ inputCount, pointCount ] = size(L);

  if pointCount == 1
    %
    % NOTE: Trying to eliminate unreasonable parfors as they
    % introduce significant overheads.
    %
    data = compute@ForwardModel.Base(this, L);
    return;
  end

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

  L = reshape(L, [ processorCount, dieCount, pointCount ]);

  E = this.E;
  D = this.D;
  BT = this.BT;
  Tamb = this.ambientTemperature;

  data = zeros(processorCount, timeCount, dieCount, pointCount);

  parfor p = 1:pointCount
    l = L(:, :, p);

    d = zeros(processorCount, timeCount, dieCount);
    X = zeros(nodeCount, dieCount);
    T = Tamb * ones(processorCount, dieCount);

    k = 1;
    i = 1;
    while k <= timeCount
      for j = i:timeIndex(k)
        X = E * X + D * (Pdyn(:, :, j) + leak(l, T));
        T = BT * X + Tamb;
      end
      d(:, k, :) = T;
      k = k + 1;
      i = j + 1;
    end

    data(:, :, :, p) = d;
  end

  data = reshape(data, processorCount, timeCount, []);
end
