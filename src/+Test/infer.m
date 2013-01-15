clear all;
close all;
setup;

rng(0);

%% Configure the test case.
%
c = Test.configure;

%% Measure temperature profiles.
%
m = Test.measure(c);

%% Construct the surrogate model.
%
s = Test.substitute(c, m);

%% Visualize some traces.
%
dimensionCount = c.dimensionCount;
processorCount = c.processorCount;
stepCount = c.timeMeasurementCount;
dieCount = c.spaceMeasurementCount;

plot(c.wafer, m.spaceMeasurementIndex);
plot(c.process, m.L);

%
% Get the Gaussian random variables used to compute the leakage
% parameters across the wafer.
%
Lnorm = (m.L - c.Lnom) / c.Ldev;
Ntrue = transpose(c.process.inverseMapping * Lnorm(:));

Ttrue = Utils.toCelsius(m.T(:, :, m.spaceMeasurementIndex));
Tmeas = Utils.toCelsius(m.Tmeas);

n = Ntrue; % randn(1, dimensionCount);
u = normcdf(n);

Tsamp = Utils.toCelsius(reshape(s.evaluate(u), ...
  [ processorCount, stepCount, dieCount ]));

time = ((1:c.powerStepCount) - 1) * c.samplingInterval;
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

  Plot.title('Die %d', m.spaceMeasurementIndex(i));
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(xlimit, ylimit);
end
