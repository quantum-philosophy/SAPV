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

  %% System.
  %
  [ c.platform, c.application ] = parseTGFF(c.tgffConfig);

  %% Schedule the application.
  %
  c.schedule = Schedule.Dense(c.platform, c.application);

  %% Obtain the dynamic power profile.
  %
  c.power = DynamicPower(c.samplingInterval);

  c.Pdyn = c.power.compute(c.schedule);

  %% Initialize the leakage model.
  %
  c.leakage = LeakagePower(c.Pdyn, 'filename', c.leakageData, ...
    'order', c.leakageOrder, 'scale', c.leakageScale);

  %% Initialize the temperature simulator.
  c.hotspot = HotSpot.Analytic(c.floorplan, c.hotspotConfig, c.hotspotLine);
end
