function c = configure
  c = Options;

  c.verbose = true;

  %
  % System
  %
  c.system = Options;
  c.system.processorCount = 2;

  taskCount = 40;
  tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', c.system.processorCount, taskCount));

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
  c.power.Pdyn = 1.5 * power.compute(schedule);
  c.power.stepCount = size(c.power.Pdyn, 2);

  %
  % Leakage power
  %
  leakageOptions = Options( ...
    'filename', File.join('+Test', 'Assets', 'inverter_45nm.leak'), ...
    'order', [ 1, 2 ], 'scale', [ 1, 0.7, 0; 1, 1, 1 ]);
  c.leakage = LeakagePower(c.power.Pdyn, leakageOptions);

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
    DataHash({ eta, lse, lou, Utils.toString(processOptions) }), '.mat' ]);

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
  c.observations.deviation = 1; % Noise!
  c.observations.dieCount = 20;
  c.observations.timeCount = 20;

  c.observations.dieIndex = Utils.randomBlocks( ...
    c.system.wafer.floorplan(:, 1), ...
    c.system.wafer.floorplan(:, 2), ...
    c.system.wafer.dieWidth, ...
    c.system.wafer.dieHeight, ...
    c.observations.dieCount);

  c.observations.timeIndex = Utils.nonrandomLine( ...
    c.power.stepCount, c.observations.timeCount);

  %
  % Surrogate
  %
  c.surrogate = Options;
  c.surrogate.nodeCount = 1e3;

  %
  % Inference.
  %
  % NOTE: Ideal scenario for now.
  %
  c.inference = Options;
  c.inference.sampleCount = 1e4;

  c.inference.proposalRate = 0.05; % ... of the standard deviation.

  % The prior on the mean of the QoI.
  c.inference.mu0 = c.process.nominal;
  c.inference.sigma20 = (0.01 * c.process.nominal)^2;

  % The prior on the variance of the QoI.
  %
  % As if from...
  c.inference.nuu = 2;
  % ... observations we concluded that it should be...
  c.inference.tau2u = c.process.deviation^2;

  % The prior on the variance of the noise.
  %
  % As if from...
  c.inference.nue = 2;
  % ... observations we concluded that it should be...
  c.inference.tau2e = c.observations.deviation^2;
end
