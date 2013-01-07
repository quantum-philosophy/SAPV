classdef Continuous < ProcessVariation.Base
  methods
    function this = Continuous(varargin)
      this = this@ProcessVariation.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    mapping = construct(this, floorplan, options)
  end
end
