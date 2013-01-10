classdef ProcessVariation < handle
  properties (Constant)
    %
    % The portion of the information that is to be preserved.
    %
    threshold = 0.95;
  end

  properties (SetAccess = 'protected')
    mapping
    expansion
    dimension
  end

  methods
    function this = ProcessVariation(wafer, varargin)
      options = Options(varargin{:});
      this.initialize(wafer, options);
    end

    function string = toString(this)
      string = sprintf('%d', this.dimension);
    end
  end

  methods (Access = 'private')
    [ expansion, mapping ] = construct(this, wafer, options)

    function initialize(this, wafer, options)
      filename = File.temporal([ class(this), '_', ...
        DataHash(Utils.toString(options)), '.mat' ]);

      if File.exist(filename)
        load(filename);
      else
        [ expansion, mapping ] = this.construct(wafer, options);
        save(filename, 'expansion', 'mapping', '-v7.3');
      end

      this.expansion = expansion;
      this.mapping = mapping;

      this.dimension = length(expansion.values);
    end
  end
end
