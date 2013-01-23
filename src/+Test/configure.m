function c = configure
  c = Options;

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
    'columns', 20, 'rows', 40);

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
  c.leakage = Options;
  c.leakage.database = File.join('+Test', 'Assets', 'inverter_45nm.leak');
  c.leakage.order = [ 1, 2 ];
  c.leakage.scale = [ 1, 0.7, 0; 1, 1, 1 ];
  c.leakage.model = LeakagePower(c.power.Pdyn, ...
    'filename', c.leakage.database, 'order', c.leakage.order, ...
    'scale', c.leakage.scale);

  %
  % Process variation
  %
  c.process = Options;
  c.process.Lnom = c.leakage.model.Lnom;
  c.process.Ldev = 0.05 * c.process.Lnom;

  eta = 0.70;
  lse = 0.10 * c.system.wafer.radius;
  lou = 0.10 * c.system.wafer.radius;

  function K = kernel(s, t)
    %
    % Squared exponential kernel.
    %
    Kse = eta * exp(-sum((s - t).^2, 1) / lse^2);

    %
    % Ornstein-Uhlenbeck kernel.
    %
    rs = sqrt(sum(s.^2, 1));
    rt = sqrt(sum(t.^2, 1));
    Kou = (1 - eta) * exp(-abs(rs - rt) / lou);

    K = Kse + Kou;
  end

  filename = File.temporal([ 'ProcessVariation_', ...
    DataHash({ eta, lse, lou }), '.mat' ]);

  if File.exist(filename)
    load(filename);
  else
    process = ProcessVariation(c.system.wafer, 'kernel', @kernel);
    save(filename, 'process', '-v7.3');
  end

  c.process.model = process;
  c.dimensionCount = process.dimensionCount;

  %
  % Observations
  %
  c.observations = Options;
  c.observations.noiseVariance = 1^2; % Squared degrees
  c.observations.spaceStepCount = 10;
  c.observations.timeStepCount = 10;

  %
  % Surrogate
  %
  c.surrogate = Options;
  c.surrogate.method = 'gaussian';

  switch lower(c.surrogate.method)
  case 'gaussian'
    c.surrogate.options = Options( ...
      'nodeCount', 1e3, 'verbose', true);
  case 'kriging'
    c.surrogate.options = Options( ...
      'nodeCount', 1e3, 'verbose', true);
  case 'asgc'
    c.surrogate.options = Options( ...
      'control', 'NormNormExpectation', ...
      'tolerance', 1e-4, ...
      'maximalLevel', 5, ...
      'verbose', true);
  otherwise
    assert(false);
  end
end
