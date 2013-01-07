setup;

samplingInterval = 1e-4; % s
processorCount = 2;
taskCount = 40;

%% Configuration.
%
[ platform, application ] = parseTGFF(File.join('+Test', 'Assets', ...
  sprintf('%03d_%03d.tgff', processorCount, taskCount)));

floorplan = File.join('+Test', 'Assets', ...
  sprintf('%03d.flp', processorCount));
hotspotConfig = File.join('+Test', 'Assets', 'hotspot.config');
hotspotLine = sprintf('sampling_intvl %e', samplingInterval);

%% Schedule the application.
%
schedule = Schedule.Dense(platform, application);

%% Obtain the dynamic power profile.
%
power = DynamicPower(samplingInterval);
Pdyn = power.compute(schedule);

%% Initialize the leakage model.
%
leakage = LeakagePower(Pdyn, ...
  'filename', File.join('+Test', 'Assets', 'inverter_45nm.leak'), ...
  'order', [ 1, 2 ], ...
  'scale', [ 1, 1, 1; 1, 1, 1 ]);

process = ProcessVariation.Continuous(floorplan);

%% Compute the corresponding temperature profile.
%
hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);

[ T, Pleak ] = hotspot.computeWithLeakage(Pdyn, leakage);
