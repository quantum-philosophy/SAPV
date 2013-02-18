classdef None < Optimization.Base
  methods
    function this = None(varargin)
      this = this@Optimization.Base(varargin{:});
    end
  end

  methods
    [ theta, covariance, coefficient ] = ...
      perform(this, theta, logPposterior, varargin)
  end
end
