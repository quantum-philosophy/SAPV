classdef Batch < HotSpot.Analytic
  methods
    function this = Batch(varargin)
      this = this@HotSpot.Analytic(varargin{:});
    end
  end

  methods (Access = 'private')
    Data = evaluate(this, Pdyn, stepIndex, leakage, U)
  end
end
