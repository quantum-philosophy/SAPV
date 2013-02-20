function c = configure(varargin)
  options = Options(varargin{:});

  c = Options;
  c.verbose = true;

  %
  % System
  %
  system = Options;
  system.processorCount = options.get('processorCount', 2);

  tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', system.processorCount, ...
      20 * system.processorCount));

  system.floorplan = File.join('+Test', 'Assets', ...
    sprintf('%03d.flp', system.processorCount));

  [ platform, application ] = parseTGFF(tgffConfig);
  system.wafer = Wafer('floorplan', system.floorplan, ...
    'columns', 20, 'rows', 20);

  c.system = system;

  schedule = Schedule.Dense(platform, application);

  %
  % Temperature
  %
  c.samplingInterval = 1e-3; % s

  temperature = Options;
  temperature.configuration = ...
    File.join('+Test', 'Assets', 'hotspot.config');
  temperature.line = ...
    sprintf('sampling_intvl %e', c.samplingInterval);

  c.temperature = temperature;

  %
  % Dynamic power
  %
  dynamicPower = DynamicPower(c.samplingInterval);

  power = Options;
  power.Pdyn = dynamicPower.compute(schedule);
  power.stepCount = size(power.Pdyn, 2);

  c.power = power;

  %
  % Leakage power
  %
  leakage = LeakagePower( ...
    'filename', File.join('+Test', 'Assets', 'inverter_45nm.leak'), ...
    'order', [ 1, 2 ], 'scale', [ 1, 0.7, 0; 1, 1, 1 ], ...
    'dynamicPower', power.Pdyn);

  c.leakage = leakage;

  %
  % Process variation
  %
  eta = 0.70;
  lse = 0.50 * system.wafer.radius;
  lou = 0.50 * system.wafer.radius;

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

  processOptions = Options( ...
    'kernel',    @correlate, ...
    'mean',      leakage.Lnom, ...
    'deviation', 0.05 * leakage.Lnom, ...
    'threshold', 0.99);

  filename = File.temporal([ 'ProcessVariation_', ...
    DataHash({ Utils.toString(system.wafer), ...
      eta, lse, lou, Utils.toString(processOptions) }), '.mat' ]);

  if File.exist(filename)
    load(filename);
  else
    process = ProcessVariation(system.wafer, processOptions);
    save(filename, 'process', '-v7.3');
  end

  c.process = process;

  %
  % Observations
  %
  observations = Options;
  observations.fixedRNG = 0; % NaN to disable.
  observations.deviation = options.get('noiseDeviation', 1); % Noise!
  observations.dieCount = options.get('dieCount', 20);
  observations.timeCount = options.get('timeCount', 20);

  observations.dieIndex = Utils.optimizedBlocks( ...
    system.wafer.floorplan(:, 5:6), observations.dieCount);

  observations.timeIndex = Utils.nonrandomLine( ...
    power.stepCount, observations.timeCount);

  c.observations = observations;

  %
  % The forward model.
  %
  forward = Options;
  forward.method = 'Parallel';

  c.forward = forward;

  %
  % Inference.
  %
  inference = Options;
  inference.method = options.get('inferenceMethod', 'StudentsT');
  inference.sampleCount = options.get('sampleCount', 1e4);
  inference.burninRate = 0.50;

  % Skip some of the parameters?
  inference.fixMuu    = true;
  inference.fixSigmau = true;
  inference.fixSigmae = true;

  inference.verbose = c.verbose;

  c.inference = inference;

  %
  % The prior distributions.
  %
  prior = Options;

  % The mean of the QoI.
  prior.mu0 = process.mean;
  prior.sigma0 = 0.01 * process.mean;

  % The variance of the QoI as if from...
  prior.nuu = 10;
  % ... observations we concluded that it should be...
  prior.tauu = 0.05 * leakage.Lnom;

  % The variance of the noise as if from...
  prior.nue = 10;
  % ... observations we concluded that it should be...
  prior.taue = 1;

  c.prior = prior;

  %
  % Optimization.
  %
  optimization = Options;
  optimization.method = 'Matlab';
  optimization.maximalStepCount = 1e4;
  optimization.stallThreshold = 1e-6;
  optimization.verbose = c.verbose;

  c.optimization = optimization;

  %
  % The proposal distribution.
  %
  proposal = Options;
  proposal.scale = 0.6;
  proposal.degreesOfFreedom = 8;

  c.proposal = proposal;

  %
  % Assessment of the proposal distribution.
  %
  assessment = Options;
  assessment.pointCount = 30;

  c.assessment = assessment;
end
