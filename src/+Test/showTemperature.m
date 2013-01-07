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

Pdyn = power.compute(schedule);
power.display(Pdyn);

%% Initialize the leakage model.
%
leakage = LeakagePower(Pdyn, ...
  'filename', File.join('+Test', 'Assets', 'inverter_45nm.leak'), ...
  'order', [ 1, 2 ], ...
  'scale', [ 1, 1, 1; 1, 1, 1 ]);

%% Compute the corresponding temperature profile.
%
hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);
display(hotspot);

[ T, Pleak ] = hotspot.computeWithLeakage(Pdyn, leakage);

%% Display everything.
%
time = hotspot.samplingInterval * (1:size(Pdyn, 2));

figure;

subplot(2, 1, 1);

Plot.title('Temperature profile');
Plot.label('Time, s', 'Temperature, C');
Plot.limit(time);
for i = 1:hotspot.processorCount
  line(time, T(i, :), 'Color', Color.pick(i));
end

subplot(2, 1, 2);

Plot.title('Power profile');
Plot.label('Time, s', 'Power, W');
Plot.limit(time);
for i = 1:hotspot.processorCount
  color = Color.pick(i);
  line(time, Pdyn(i, :), 'Color', color);
  line(time, Pleak(i, :), 'Color', color, 'LineStyle', '--');
end
