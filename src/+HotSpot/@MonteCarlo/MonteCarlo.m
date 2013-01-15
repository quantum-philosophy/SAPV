classdef MonteCarlo < HotSpot.Analytic
  methods
    function this = MonteCarlo(varargin)
      options = Options(varargin{:});
      this = this@HotSpot.Analytic(options);
    end
  end
end
