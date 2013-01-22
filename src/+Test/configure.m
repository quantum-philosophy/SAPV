function c = configure
  %
  % System
  %
  c.processorCount = 2;

  taskCount = 40;
  tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', c.processorCount, taskCount));

  c.floorplan = File.join('+Test', 'Assets', ...
    sprintf('%03d.flp', c.processorCount));

  [ platform, application ] = parseTGFF(tgffConfig);
  c.wafer = Wafer('floorplan', c.floorplan, 'columns', 20, 'rows', 40);

  %
  % Schedule
  %
  schedule = Schedule.Dense(platform, application);

  %
  % Temperature
  %
  c.samplingInterval = 1e-3; % s
  c.hotspotConfig = File.join('+Test', 'Assets', 'hotspot.config');
  c.hotspotLine = sprintf('sampling_intvl %e', c.samplingInterval);

  %
  % Dynamic power
  %
  power = DynamicPower(c.samplingInterval);
  c.Pdyn = power.compute(schedule);
  c.powerStepCount = size(c.Pdyn, 2);

  %
  % Leakage power
  %
  leakageData = File.join('+Test', 'Assets', 'inverter_45nm.leak');
  leakageOrder = [ 1, 2 ];
  leakageScale = [ 1, 0.7, 0; 1, 1, 1 ];

  c.leakage = LeakagePower(c.Pdyn, 'filename', leakageData, ...
    'order', leakageOrder, 'scale', leakageScale);

  %
  % Process variation
  %
  c.Lnom = c.leakage.Lnom;
  c.Ldev = 0.05 * c.Lnom;

  w1 =     0.70;
  w2 = 1 - 0.70;
  l1 = 0.10 * c.wafer.radius;
  l2 = 0.10 * c.wafer.radius;

  function K = kernel(s, t)
    K1 = w1 * exp(-sum(abs(s - t), 1) / l1);

    rs = sqrt(sum(s.^2, 1));
    rt = sqrt(sum(t.^2, 1));
    K2 = w2 * exp(-abs(rs - rt) / l2);

    K = K1 + K2;
  end

  filename = File.temporal([ 'ProcessVariation_', ...
    DataHash({ w1, w2, l1, l2 }), '.mat' ]);

  if File.exist(filename)
    load(filename);
  else
    process = ProcessVariation(c.wafer, 'kernel', @kernel);
    save(filename, 'process', '-v7.3');
  end

  c.process = process;
  c.dimensionCount = process.dimensionCount;

  %
  % Measurements
  %
  c.noiseVariance = 1^2; % Squared degrees
  c.spaceMeasurementCount = 10;
  c.timeMeasurementCount = 10;

  %
  % Surrogate
  %
  c.surrogateMethod = 'gaussian';

  switch lower(c.surrogateMethod)
  case 'gaussian'
    c.surrogateOptions = Options( ...
      'nodeCount', 1e3, 'verbose', true);
  case 'kriging'
    c.surrogateOptions = Options( ...
      'nodeCount', 1e3, 'verbose', true);
  case 'asgc'
    c.surrogateOptions = Options( ...
      'control', 'NormNormExpectation', ...
      'tolerance', 1e-4, ...
      'maximalLevel', 5, ...
      'verbose', true);
  otherwise
    assert(false);
  end
end
