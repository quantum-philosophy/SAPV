classdef Base < HotSpot.Analytic
  properties (SetAccess = 'private')
    leakage
    dieCount
    timeIndex
    Pdyn
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});

      this = this@HotSpot.Analytic(options);

      Pdyn = options.Pdyn;

      this.leakage = options.leakage;
      this.dieCount = options.dieCount;
      this.timeIndex = options.get('timeIndex', 1:size(Pdyn, 2));
      this.Pdyn = permute(repmat(Pdyn, ...
        [ 1, 1, this.dieCount ]), [ 1, 3, 2 ]);
    end
  end

  methods (Abstract)
    data = compute(this, L)
  end
end
