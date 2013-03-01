classdef Sequential < ForwardModel.Base
  methods
    function this = Sequential(varargin)
      this = this@ForwardModel.Base(varargin{:});
    end
  end
end
