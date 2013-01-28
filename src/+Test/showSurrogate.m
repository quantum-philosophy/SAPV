clear all;
close all;
setup;

Utils.fixRNG;

%% Configure the test case.
%
c = Test.configure;

%% Measure temperature profiles.
%
fprintf('Measurements: simulation...\n');
time = tic;
m = Utils.measure(c);
fprintf('Measurements: done in %.2f seconds.\n', toc(time));

%% Display the wafer and chosen dies.
%
plot(c.system.wafer, c.observations.dieIndex);

%% Plot the distribution of the channel length and maximal temperature.
%
nRange = [ -3, 3 ];
Trange = [ 45, 120 ];

plot(c.process, m.n);
Plot.title('Quantity of interest (normalized)');
colormap(Color.map(m.n, nRange));

T = max(squeeze(max(m.T, [], 2)), [], 1);
T = Utils.toCelsius(repmat(T, c.system.processorCount, 1));

plot(c.process, T);
Plot.title('Maximal temperature');
colormap(Color.map(T, Trange));

%% Construct the surrogate model.
%
time = tic;
fprintf('Surrogate: construction...\n');
s = Utils.substitute(c);
fprintf('Surrogate: done in %.2f seconds.\n', toc(time));

%% Visualize some traces.
%
processorCount = c.system.processorCount;
stepCount = c.observations.timeCount;
dieCount = c.observations.dieCount;

Ttrue = Utils.toCelsius(m.T(:, :, c.observations.dieIndex));
Tmeas = Utils.toCelsius(m.Tmeas);

Tsamp = Utils.toCelsius(reshape(s.evaluate(normcdf(m.z')), ...
  [ processorCount, stepCount, dieCount ]));

time = ((1:c.power.stepCount) - 1) * c.samplingInterval;
measurementTime = (c.observations.timeIndex - 1) * c.samplingInterval;

xlimit = [ time(1), time(end) ];
ylimit = [ Ttrue(:); Tmeas(:); Tsamp(:) ];
ylimit = [ min(ylimit), max(ylimit) ];

for i = 1:dieCount
  figure;

  for j = 1:processorCount
    color = Color.pick(j);
    line(time, Ttrue(j, :, i), 'Color', color);
    line(measurementTime, Tmeas(j, :, i), 'Color', color, ...
      'LineStyle', 'None', 'Marker', 'o');
    line(measurementTime, Tsamp(j, :, i), 'Color', color, ...
      'LineStyle', 'None', 'Marker', 'x');
  end

  Plot.title('Sample %d, die %d', i, c.observations.dieIndex(i));
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(xlimit, ylimit);
end
