classdef Surrogate < HotSpot.Analytic
  methods
    function this = Surrogate(varargin)
      options = Options(varargin{:});
      this = this@HotSpot.Analytic(options);
    end
  end

  methods (Access = 'private')
    Data = evaluate(this, Pdyn, stepIndex, leakage, L)
  end
end
