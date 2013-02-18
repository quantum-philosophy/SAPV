classdef Base < handle
  methods
    function this = Base(varargin)
    end
  end

  methods (Abstract)
    [ theta, covariance, coefficient ] = ...
      perform(this, theta, logPposterior, varargin)
  end
end
