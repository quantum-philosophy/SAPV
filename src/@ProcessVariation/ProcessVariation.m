classdef ProcessVariation < handle
  properties (Constant)
    %
    % The portion of the information that is to be preserved.
    %
    threshold = 0.99;
  end

  properties (SetAccess = 'protected')
    wafer
    mapping
    expansion
  end

  methods
    function this = ProcessVariation(wafer, varargin)
      options = Options(varargin{:});
      this.initialize(wafer, options);
    end

    function result = sample(this)
      dimensionCount = size(this.mapping, 2);
      dieCount = this.wafer.dieCount;
      processorCount = this.wafer.processorCount;
      result = this.mapping * randn(dimensionCount, 1);
      result = reshape(result, [ processorCount, dieCount ]);
    end

    function string = toString(this)
      string = Utils.toString(size(this.mapping));
    end
  end

  methods (Access = 'private')
    [ expansion, mapping ] = construct(this, wafer, options)

    function initialize(this, wafer, options)
      this.wafer = wafer;

      filename = File.temporal([ class(this), '_', ...
        DataHash({ this.threshold, Utils.toString(options) }), '.mat' ]);

      if File.exist(filename)
        load(filename);
      else
        [ expansion, mapping ] = this.construct(wafer, options);
        save(filename, 'expansion', 'mapping', '-v7.3');
      end

      this.expansion = expansion;
      this.mapping = mapping;
    end
  end
end
