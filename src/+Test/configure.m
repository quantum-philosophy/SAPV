function c = configure()
  c.samplingInterval = 1e-4; % s
  c.processorCount = 2;
  c.taskCount = 40;

  c.tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', c.processorCount, c.taskCount));

  c.floorplan = File.join('+Test', 'Assets', ...
    sprintf('%03d.flp', c.processorCount));

  c.hotspotConfig = File.join('+Test', 'Assets', 'hotspot.config');
  c.hotspotLine = sprintf('sampling_intvl %e', c.samplingInterval);

  c.leakageData = File.join('+Test', 'Assets', 'inverter_45nm.leak');
  c.leakageOrder = [ 1, 2 ];
  c.leakageScale = [ 1, 1, 1; 1, 1, 1 ];

  %% System
  %
  [ c.platform, c.application ] = parseTGFF(c.tgffConfig);
  c.wafer = Wafer('floorplan', c.floorplan);

  %% Schedule
  %
  c.schedule = Schedule.Dense(c.platform, c.application);

  %% Dynamic power profile
  %
  c.power = DynamicPower(c.samplingInterval);
  c.Pdyn = c.power.compute(c.schedule);

  %% Leakage model
  %
  c.leakage = LeakagePower(c.Pdyn, 'filename', c.leakageData, ...
    'order', c.leakageOrder, 'scale', c.leakageScale);

  %% Process variation
  %
  c.process = ProcessVariation(c.wafer);
end
