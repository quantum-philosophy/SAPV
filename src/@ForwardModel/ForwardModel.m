classdef ForwardModel < HotSpot.Analytic
  properties (SetAccess = 'private')
    leakage
    dieCount
    timeIndex
    Pdyn
  end

  methods
    function this = ForwardModel(varargin)
      options = Options(varargin{:});

      this = this@HotSpot.Analytic(options);

      this.leakage = options.leakage;
      this.dieCount = options.dieCount;
      this.timeIndex = options.timeIndex;
      Pdyn = options.Pdyn;
      this.Pdyn = reshape(kron(Pdyn, ones(1, this.dieCount)), ...
        [ this.processorCount, this.dieCount, size(Pdyn, 2) ]);
    end
  end
end
