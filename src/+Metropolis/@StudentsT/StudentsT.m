classdef StudentsT < Metropolis.Base
  methods
    function this = StudentsT(varargin)
      this = this@Metropolis.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    proposal = optimize(this, theta, computeFitness)
    sample = propose(this, ~, proposal, count)
  end
end
