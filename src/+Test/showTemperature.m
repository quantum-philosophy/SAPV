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

plot(schedule);
display(schedule);

%% Obtain the dynamic power profile.
%
power = DynamicPower(samplingInterval);
powerProfile = power.compute(schedule);

power.display(powerProfile);
power.plot(powerProfile);

%% Compute the corresponding temperature profile.
%
hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);
temperatureProfile = hotspot.compute(powerProfile);

display(hotspot);
hotspot.plot(temperatureProfile);
