classdef ForwardModel < HotSpot.Analytic
  properties (SetAccess = 'private')
    timeIndex

    leakage
    process

    dieCount
    mapping

    Pdyn
  end

  methods
    function this = ForwardModel(varargin)
      options = Options(varargin{:});

      this = this@HotSpot.Analytic(options);

      this.timeIndex = options.timeIndex;

      this.leakage = options.leakage;
      this.process = options.process;

      dieIndex = options.dieIndex;
      if isempty(dieIndex)
        this.dieCount = this.process.wafer.dieCount;
        this.mapping = this.process.mapping;
      else
        this.dieCount = length(dieIndex);
        this.mapping = this.process.constrainMapping(dieIndex);
      end

      Pdyn = options.Pdyn;
      this.Pdyn = reshape(kron(Pdyn, ones(1, this.dieCount)), ...
        [ this.processorCount, this.dieCount, size(Pdyn, 2) ]);
    end
  end
end
