setup;

c = Test.configure;

Pdyn = c.power.Pdyn;

hs = HotSpot.Analytic('floorplan', c.system.floorplan, ...
  'config', c.temperature.configuration, 'line', c.temperature.line);

[ T, Pleak ] = hs.compute(Pdyn, c.leakage.model);
T = Utils.toCelsius(T);

figure;
time = hs.samplingInterval * (1:size(Pdyn, 2));

%% Temperature profile.
%
subplot(2, 1, 1);
Plot.title('Temperature profile');
Plot.label('Time, s', 'Temperature, C');
Plot.limit(time);
for i = 1:hs.processorCount
  line(time, T(i, :), 'Color', Color.pick(i));
end

%% Dynamic and leakage power profiles.
%
subplot(2, 1, 2);
Plot.title('Power profile');
Plot.label('Time, s', 'Power, W');
Plot.limit(time);
for i = 1:hs.processorCount
  color = Color.pick(i);
  line(time, Pdyn(i, :), 'Color', color);
  line(time, Pleak(i, :), 'Color', color, 'LineStyle', '--');
end
