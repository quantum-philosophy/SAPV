classdef ProcessVariation < handle
  properties (Constant)
    %
    % The portion of the information that is to be preserved.
    %
    threshold = 0.99;
  end

  properties (SetAccess = 'protected')
    wafer
    expansion
    mapping
    inverseMapping
    dimensionCount
  end

  methods
    function this = ProcessVariation(wafer, varargin)
      options = Options(varargin{:});
      this.initialize(wafer, options);
    end

    function [ mapping, inverseMapping ] = constrainMapping(this, index)
      processorCount = this.wafer.processorCount;
      dieCount = length(index);

      I = zeros(1, processorCount * dieCount);
      for i = 1:dieCount
        j = index(i);
        I(((i - 1) * processorCount + 1):(i * processorCount)) = ...
          ((j - 1) * processorCount + 1):(j * processorCount);
      end

      mapping = this.mapping(I, :);
      inverseMapping = this.inverseMapping(:, I);
    end

    function result = sample(this)
      dieCount = this.wafer.dieCount;
      processorCount = this.wafer.processorCount;
      result = this.mapping * randn(this.dimensionCount, 1);
      result = reshape(result, [ processorCount, dieCount ]);
    end

    function string = toString(this)
      string = Utils.toString(size(this.mapping));
    end
  end

  methods (Access = 'private')
    [ expansion, mapping, inverseMapping ] = construct(this, wafer, options)

    function initialize(this, wafer, options)
      this.wafer = wafer;

      filename = File.temporal([ class(this), '_', ...
        DataHash({ this.threshold, Utils.toString(options) }), '.mat' ]);

      if File.exist(filename)
        load(filename);
      else
        [ expansion, mapping, inverseMapping ] = ...
          this.construct(wafer, options);
        save(filename, 'expansion', 'mapping', ...
          'inverseMapping', '-v7.3');
      end

      this.expansion = expansion;
      this.mapping = mapping;
      this.inverseMapping = inverseMapping;
      this.dimensionCount = size(mapping, 2);
    end
  end
end
