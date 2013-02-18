classdef Base < handle
  methods
    function this = Base(varargin)
    end
  end

  methods (Abstract, Access = 'protected')
    theta = propose(this, theta, proposal)
  end
end
