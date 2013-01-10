classdef MonteCarlo < HotSpot.Analytic
  properties (SetAccess = 'private')
    wafer
  end

  methods
    function this = MonteCarlo(varargin)
      options = Options(varargin{:});
      this = this@HotSpot.Analytic(options);
      this.wafer = options.wafer;
    end

    function [ T, L ] = compute(this, Pdyn, varargin)
      [ processorCount, stepCount ] = size(Pdyn);

      options = Options(varargin{:});

      wafer = this.wafer;
      leakage = options.leakage;
      process = options.process;

      if options.get('verbose', false)
        verbose = @(varargin) fprintf(varargin{:});
      else
        verbose = @(varargin) [];
      end

      dimension = process.dimension;
      dieCount = wafer.dieCount;

      filename = File.temporal(sprintf('MonteCarlo_%s.mat', ...
        DataHash({ Pdyn, Utils.toString(leakage), Utils.toString(process) })));

      if File.exist(filename)
        verbose('Monte Carlo: using cached data in "%s"...\n', filename);
        load(filename);
      else
        verbose('Monte Carlo: running %d simulations...\n', dieCount);

        rvs = normrnd(0, 1, dimension, 1);

        Lnom = leakage.Lnom;
        Ldev = 0.05 * Lnom;
        Lmap = process.mapping;

        T = zeros(processorCount, stepCount, dieCount);
        L = zeros(processorCount, dieCount);

        tic;
        for i = 1:dieCount
          L(:, i) = Lnom + Ldev * Lmap(:, :, i) * rvs;
          T(:, :, i) = compute@HotSpot.Analytic(this, Pdyn, leakage, L(:, i));
        end
        time = toc;

        save(filename, 'L', 'T', 'time', '-v7.3');
      end
      verbose('Monte Carlo: simulation time %.2f s (%d samples).\n', ...
        time, dieCount);

      T = permute(T, [ 3 1 2 ]);
    end
  end
end
