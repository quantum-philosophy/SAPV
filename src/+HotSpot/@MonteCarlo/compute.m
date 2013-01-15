function [ T, L ] = compute(this, Pdyn, varargin)
  [ processorCount, stepCount ] = size(Pdyn);

  options = Options(varargin{:});

  leakage = options.leakage;
  process = options.process;
  wafer = process.wafer;

  dieCount = wafer.dieCount;

  Lnom = options.Lnom;
  Ldev = options.Ldev;
  L = Lnom + Ldev * process.sample;

  T = zeros(processorCount, stepCount, dieCount);

  for i = 1:dieCount
    T(:, :, i) = compute@HotSpot.Analytic( ...
      this, Pdyn, leakage, L(:, i));
  end
end
