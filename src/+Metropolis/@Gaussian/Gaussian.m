classdef Gaussian < Metropolis.Base
  methods
    function this = Gaussian(varargin)
      this = this@Metropolis.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    sample = propose(this, sample, proposal)
  end
end
