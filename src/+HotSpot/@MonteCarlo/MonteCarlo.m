classdef MonteCarlo < HotSpot.Numeric & ProcessVariation.Discrete
  properties (SetAccess = 'private')
    sampleCount
    filename
    verbose
  end

  methods
    function this = MonteCarlo(floorplan, config, line, varargin)
      options = Options(varargin{:});

      this = this@HotSpot.Numeric(floorplan, config, line);
      this = this@ProcessVariation.Discrete(floorplan, ...
        'reduction', 'none');

      this.sampleCount = options.get('sampleCount', 1e3);
      this.filename = options.get('filename', []);
      if options.get('verbose', false)
        this.verbose = @(varargin) fprintf(varargin{:});
      else
        this.verbose = @(varargin) [];
      end
    end

    function [ Texp, Tvar, Tdata ] = computeWithLeakageInParallel( ...
      this, Pdyn, leakage)

      [ processorCount, stepCount ] = size(Pdyn);
      sampleCount = this.sampleCount;

      verbose = this.verbose;

      filename = this.filename;
      if isempty(filename)
        filename = sprintf('MonteCarlo_%s.mat', ...
          DataHash({ Pdyn, Utils.toString(leakage), sampleCount }));
      end

      if File.exist(filename)
        verbose('Monte Carlo: using cached data in "%s"...\n', filename);
        load(filename);
        if ~exist('time', 'var'), time = 0; end
      else
        verbose('Monte Carlo: running %d simulations...\n', sampleCount);

        rvs = normrnd(0, 1, this.dimension, sampleCount);

        Lnom = this.Lnom;
        Ldev = this.Ldev;
        Lmap = this.Lmap;

        Tdata = zeros(processorCount, stepCount, sampleCount);

        tic;
        parfor i = 1:sampleCount
          Tdata(:, :, i) = this.computeWithLeakage( ...
            Pdyn, leakage, Lnom + Ldev * Lmap * rvs(:, i));
        end
        time = toc;

        Texp = mean(Tdata, 3);
        Tvar = var(Tdata, [], 3);

        save(filename, 'Texp', 'Tvar', 'Tdata', 'time', '-v7.3');
      end
      verbose('Monte Carlo: simulation time %.2f s (%d samples).\n', ...
        time, sampleCount);

      Tdata = permute(Tdata, [ 3 1 2 ]);
    end

   function Tdata = evaluateWithLeakageInParallel( ...
      this, Pdyn, leakage, rvs)

      [ processorCount, stepCount ] = size(Pdyn);

      rvs = this.Lnom + this.Ldev * this.Lmap * rvs.';
      sampleCount = size(rvs, 2);

      Lnom = leakage.Lnom;
      rvMap = this.rvMap;

      Tdata = zeros(processorCount, stepCount, sampleCount);

      parfor i = 1:sampleCount
        Tdata(:, :, i) = this.computeWithLeakage( ...
          Pdyn, leakage, rvs(:, i));
      end

      Tdata = permute(Tdata, [ 3 1 2 ]);
    end
  end
end
