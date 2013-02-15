classdef DependentNormal < MetropolisHastings.Base
  methods
    function this = DependentNormal(varargin)
      this = this@MetropolisHastings.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    sample = propose(this, sample, proposal)
  end
end
