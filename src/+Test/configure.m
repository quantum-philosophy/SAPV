function c = configure
  %
  % System
  %
  c.processorCount = 2;
  c.taskCount = 40;
  c.tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', c.processorCount, c.taskCount));
  c.floorplan = File.join('+Test', 'Assets', ...
    sprintf('%03d.flp', c.processorCount));

  [ c.platform, c.application ] = parseTGFF(c.tgffConfig);
  c.wafer = Wafer('floorplan', c.floorplan, 'columns', 20, 'rows', 40);

  %
  % Schedule
  %
  c.schedule = Schedule.Dense(c.platform, c.application);

  %
  % Temperature
  %
  c.samplingInterval = 1e-4; % s
  c.hotspotConfig = File.join('+Test', 'Assets', 'hotspot.config');
  c.hotspotLine = sprintf('sampling_intvl %e', c.samplingInterval);

  %
  % Dynamic power
  %
  c.power = DynamicPower(c.samplingInterval);
  c.Pdyn = c.power.compute(c.schedule);

  %
  % Leakage power
  %
  c.leakageData = File.join('+Test', 'Assets', 'inverter_45nm.leak');
  c.leakageOrder = [ 1, 2 ];
  c.leakageScale = [ 1, 1, 1; 1, 1, 1 ];

  c.leakage = LeakagePower(c.Pdyn, 'filename', c.leakageData, ...
    'order', c.leakageOrder, 'scale', c.leakageScale);

  %
  % Process variation
  %
  c.correlationLength = c.wafer.radius;
  c.correlationKernel = @(s, t) exp(-abs(s - t) / c.correlationLength);

  c.process = ProcessVariation(c.wafer, ...
    'method', 'discrete', 'kernel', c.correlationKernel);
end
