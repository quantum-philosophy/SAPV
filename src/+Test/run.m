clear all;
close all;
setup;

rng(1);

%% Configure the test case.
%
c = Test.configure;

Lnom = c.process.Lnom;
Ldev = c.process.Ldev;

%% Measure temperature profiles.
%
m = Test.measure(c);

%% Display the wafer and chosen dies.
%
plot(c.system.wafer, m.spaceMeasurementIndex);

%% Plot the distribution of the channel length and maximal temperature.
%
Lrange = [ Lnom - 3 * Ldev, Lnom + 3 * Ldev ];
Trange = [ 45, 120 ];

plot(c.process.model, m.L);
Plot.title('Channel length');
colormap(Color.map(m.L, Lrange));

T = max(squeeze(max(m.T, [], 2)), [], 1);
T = Utils.toCelsius(repmat(T, c.system.processorCount, 1));

plot(c.process.model, T);
Plot.title('Maximal temperature');
colormap(Color.map(T, Trange));

%% Construct the surrogate model.
%
s = Test.substitute(c, m);

%% Visualize some traces.
%
dimensionCount = c.dimensionCount;
processorCount = c.system.processorCount;
stepCount = c.observations.timeStepCount;
dieCount = c.observations.spaceStepCount;

%
% Get the Gaussian random variables used to compute the leakage
% parameters across the wafer.
%
Lnorm = (m.L - Lnom) / Ldev;
Ntrue = transpose(c.process.model.inverseMapping * Lnorm(:));

Ttrue = Utils.toCelsius(m.T(:, :, m.spaceMeasurementIndex));
Tmeas = Utils.toCelsius(m.Tmeas);

n = Ntrue;
u = normcdf(n);

Tsamp = Utils.toCelsius(reshape(s.evaluate(u), ...
  [ processorCount, stepCount, dieCount ]));

time = ((1:c.power.stepCount) - 1) * c.samplingInterval;
measurementTime = (m.timeMeasurementIndex - 1) * c.samplingInterval;

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

  Plot.title('Sample %d, die %d', i, m.spaceMeasurementIndex(i));
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(xlimit, ylimit);
end
