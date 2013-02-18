classdef Matlab < Optimization.Base
  methods
    function this = Matlab(varargin)
      this = this@Optimization.Base(varargin{:});
    end
  end

  methods
    [ theta, covariance, coefficient ] = ...
      perform(this, theta, logPposterior, varargin)
  end
end
