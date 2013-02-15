classdef IndependentT < MetropolisHastings.Base
  methods
    function this = IndependentT(varargin)
      this = this@MetropolisHastings.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    proposal = optimize(this, theta, computeFitness)
    sample = propose(this, sample, proposal)
  end
end
