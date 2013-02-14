function c = configure(varargin)
  options = Options(varargin{:});

  c = Options;

  c.verbose = true;
  c.stamp = @stamp;

  function string = stamp(name, varargin)
    hash = DataHash({ c.toString, varargin });

    match = regexp(name, '^(.)+\.([^.])+$', 'tokens');
    if ~isempty(match)
      name = match{1}{1};
      extension = match{1}{2};
    else
      extension = [];
    end

    string = sprintf('%03d_%s_%s', ...
      c.system.processorCount, name, hash);

    if ~isempty(extension)
      string = [ string, '.', extension ];
    end
  end

  if c.verbose
    c.printf = @(varargin) fprintf(varargin{:});
  else
    c.printf = @(varargin) [];
  end

  %
  % System
  %
  c.system = Options;
  c.system.processorCount = options.get('processorCount', 2);

  tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', c.system.processorCount, ...
      20 * c.system.processorCount));

  c.system.floorplan = File.join('+Test', 'Assets', ...
    sprintf('%03d.flp', c.system.processorCount));

  [ platform, application ] = parseTGFF(tgffConfig);
  c.system.wafer = Wafer('floorplan', c.system.floorplan, ...
    'columns', 20, 'rows', 20);

  schedule = Schedule.Dense(platform, application);

  %
  % Temperature
  %
  c.samplingInterval = 1e-3; % s

  c.temperature = Options;
  c.temperature.configuration = ...
    File.join('+Test', 'Assets', 'hotspot.config');
  c.temperature.line = ...
    sprintf('sampling_intvl %e', c.samplingInterval);

  %
  % Dynamic power
  %
  power = DynamicPower(c.samplingInterval);

  c.power = Options;
  c.power.Pdyn = power.compute(schedule);
  c.power.stepCount = size(c.power.Pdyn, 2);

  %
  % Leakage power
  %
  leakageOptions = Options( ...
    'filename', File.join('+Test', 'Assets', 'inverter_45nm.leak'), ...
    'order', [ 1, 2 ], 'scale', [ 1, 0.7, 0; 1, 1, 1 ], ...
    'dynamicPower', c.power.Pdyn);
  c.leakage = LeakagePower(leakageOptions);

  %
  % Process variation
  %
  eta = 0.70;
  lse = 0.50 * c.system.wafer.radius;
  lou = 0.50 * c.system.wafer.radius;

  processOptions = Options( ...
    'kernel',    @correlate, ...
    'nominal',   c.leakage.Lnom, ...
    'deviation', 0.05 * c.leakage.Lnom, ...
    'threshold', 0.99);

  function K = correlate(s, t)
    %
    % Squared exponential kernel.
    %
    Kse = exp(-sum((s - t).^2, 1) / lse^2);

    %
    % Ornstein-Uhlenbeck kernel.
    %
    rs = sqrt(sum(s.^2, 1));
    rt = sqrt(sum(t.^2, 1));
    Kou = exp(-abs(rs - rt) / lou);

    K = eta * Kse + (1 - eta) * Kou;
  end

  filename = File.temporal([ 'ProcessVariation_', ...
    DataHash({ Utils.toString(c.system.wafer), ...
      eta, lse, lou, Utils.toString(processOptions) }), '.mat' ]);

  if File.exist(filename)
    load(filename);
  else
    process = ProcessVariation(c.system.wafer, processOptions);
    save(filename, 'process', '-v7.3');
  end

  c.process = process;

  %
  % Observations
  %
  c.observations = Options;
  c.observations.fixedRNG = 0; % NaN to disable.
  c.observations.deviation = options.get('noiseDeviation', 1); % Noise!
  c.observations.dieCount = options.get('dieCount', 20);
  c.observations.timeCount = options.get('timeCount', 20);

  c.observations.dieIndex = Utils.optimizedBlocks( ...
    c.system.wafer.floorplan(:, 5:6), c.observations.dieCount);

  c.observations.timeIndex = Utils.nonrandomLine( ...
    c.power.stepCount, c.observations.timeCount);

  %
  % Surrogate
  %
  c.surrogate = Options;
  c.surrogate.nodeCount = NaN;
  c.surrogate.optimizationStepCount = 1e2;

  %
  % Inference.
  %
  % NOTE: Ideal scenario for now.
  %
  c.inference = Options;
  c.inference.sampleCount = options.get('sampleCount', 1e4);
  c.inference.burninRate = 0.50;

  % The prior on the mean of the QoI.
  c.inference.mu0 = c.process.nominal;
  c.inference.sigma0 = 0.01 * c.process.nominal;

  % The prior on the variance of the QoI.
  %
  % As if from...
  c.inference.nuu = 10;
  % ... observations we concluded that it should be...
  c.inference.tauu = 0.05 * c.leakage.Lnom;

  % The prior on the variance of the noise.
  %
  % As if from...
  c.inference.nue = 10;
  % ... observations we concluded that it should be...
  c.inference.taue = 1;

  % Skip some of the parameters?
  c.inference.fixMuu    = true;
  c.inference.fixSigmau = true;
  c.inference.fixSigmae = true;

  % The proposal distribution.
  c.inference.optimization = Options;
  c.inference.optimization.method = 'fminunc';
  c.inference.optimization.maximalStepCount = 1e4;
  c.inference.optimization.stallThreshold = 1e-6;

  c.inference.proposalRate = 0.5; % ... a portion of the standard deviation.
  c.inference.assessProposal = true;
  c.inference.assessmentPointCount = 30;
end
