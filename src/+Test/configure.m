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
  c.samplingInterval = 1e-4; % s
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
  leakageScale = [ 1, 1, 1; 1, 1, 1 ];

  c.leakage = LeakagePower(c.Pdyn, 'filename', leakageData, ...
    'order', leakageOrder, 'scale', leakageScale);

  %
  % Process variation
  %
  c.correlationLength = c.wafer.radius;
  c.correlationKernel = @(s, t) exp(-(s - t).^2 / c.correlationLength.^2);

  c.process = ProcessVariation(c.wafer, ...
    'method', 'numeric', 'kernel', c.correlationKernel);

  %
  % Measurements
  %
  c.noiseVariance = 1^2; % Squared degrees
  c.spaceMeasurementCount = 10;
  c.timeMeasurementCount = 10;

  %
  % Surrogate
  %
  c.surrogateOptions = Options( ...
    'adaptivityControl', 'NormNormExpectation', ...
    'tolerance', 1e-4, ...
    'maximalLevel', 10, ...
    'verbose', true);
end
