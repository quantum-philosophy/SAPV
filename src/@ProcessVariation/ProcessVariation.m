classdef ProcessVariation < handle
  properties (SetAccess = 'protected')
    wafer

    mean
    deviation
    threshold
    mapping

    dimensionCount
  end

  methods
    function this = ProcessVariation(wafer, varargin)
      options = Options(varargin{:});

      this.wafer = wafer;

      this.mean = options.mean;
      this.deviation = options.deviation;
      this.threshold = options.get('threshold', 0.99);
      this.mapping = this.construct(wafer, options);

      this.dimensionCount = size(this.mapping, 2);
    end

    function mapping = constrainMapping(this, index)
      processorCount = this.wafer.processorCount;
      dieCount = length(index);

      I = zeros(1, processorCount * dieCount);
      for i = 1:dieCount
        j = index(i);
        I(((i - 1) * processorCount + 1):(i * processorCount)) = ...
          ((j - 1) * processorCount + 1):(j * processorCount);
      end

      mapping = this.mapping(I, :);
    end

    function [ u, n ] = compute(this, z, mean, deviation)
      if nargin < 3, mean = this.mean; end
      if nargin < 4, deviation = this.deviation; end

      n = reshape(this.mapping * z, ...
        [ this.wafer.processorCount, this.wafer.dieCount ]);

      u = mean + deviation * n;
    end

    function [ u, n, z ] = sample(this)
      z = randn(this.dimensionCount, 1);
      n = reshape(this.mapping * z, ...
        [ this.wafer.processorCount, this.wafer.dieCount ]);
      u = this.mean + this.deviation * n;
    end

    function string = toString(this)
      string = Utils.toString([ this.threshold, ...
        this.mean, this.deviation, this.dimensionCount ]);
    end
  end

  methods (Access = 'private')
    mapping = construct(this, wafer, options)
  end
end
