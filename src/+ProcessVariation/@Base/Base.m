classdef Base < handle
  properties (Constant)
    Lnom = LeakagePower.Lnom;
    Ldev = LeakagePower.Lnom * 0.05;

    %
    % The portion of the information that is to be preserved.
    %
    threshold = 0.99;

    %
    % The contribution of the global variations.
    %
    globalPortion = 0.5;
  end

  properties (SetAccess = 'protected')
    Lmap
    dimension
  end

  methods
    function this = Base(floorplan, varargin)
      options = Options(varargin{:});
      this.initialize(floorplan, options);
    end
  end

  methods (Abstract, Access = 'protected')
    mapping = construct(this, floorplan, options)
  end

  methods (Access = 'private')
    function initialize(this, floorplan, options)
      P = this.construct(floorplan, options);

      portion = this.globalPortion;
      processorCount = size(P, 1);

      this.Lmap = [ sqrt(1 - portion) * P, ...
        sqrt(portion) * ones(processorCount, 1) ];
      this.dimension = size(this.Lmap, 2);
    end
  end
end
