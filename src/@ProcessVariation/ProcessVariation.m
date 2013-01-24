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
    inverseMapping
    dimensionCount
  end

  methods
    function this = ProcessVariation(wafer, varargin)
      options = Options(varargin{:});
      this.wafer = wafer;
      [ this.mapping, this.inverseMapping ] = this.construct(wafer, options);
      this.dimensionCount = size(this.mapping, 2);
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

    function [ result, z ] = sample(this)
      dieCount = this.wafer.dieCount;
      processorCount = this.wafer.processorCount;
      z = randn(this.dimensionCount, 1);
      result = reshape(this.mapping * z, [ processorCount, dieCount ]);
    end

    function string = toString(this)
      string = Utils.toString(size(this.mapping));
    end
  end

  methods (Access = 'private')
    [ mapping, inverseMapping ] = construct(this, wafer, options)
  end
end
