classdef Forward < HotSpot.Analytic
  properties (SetAccess = 'private')
    Pdyn
    timeIndex
    leakage

    Zmap
    Lnom
    Ldev

    dimensionCount
    dieCount
  end

  methods
    function this = Forward(varargin)
      options = Options(varargin{:});

      this = this@HotSpot.Analytic(options);

      this.dieCount = options.dieCount;

      Pdyn = options.Pdyn;
      this.Pdyn = reshape(kron(Pdyn, ones(1, this.dieCount)), ...
        [ this.processorCount, this.dieCount, size(Pdyn, 2) ]);

      this.timeIndex = options.timeIndex;
      this.leakage = options.leakage;

      this.Zmap = options.Zmap;
      this.Lnom = options.Lnom;
      this.Ldev = options.Ldev;

      this.dimensionCount = size(this.Zmap, 2);
    end
  end
end
