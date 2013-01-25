clear all;
close all;
setup;

Utils.fixRNG;

%% Configure the test case.
%
c = Test.configure;

%% Measure temperature profiles.
%
m = Utils.measure(c);

%% Initialize the forward model.
%
model = Utils.forward(c, 'model', 'observed');

%% Do the inference.
%
[ samples, fitness, acceptedCount ] = Utils.infer( ...
  'data', m.Tmeas, 'model', model, 'verbose', true, c.inference);

muu     = samples(:, 1);
sigma2u = samples(:, 2);
sigma2e = samples(:, 3);
z       = samples(:, 4:end);

time = 1:size(samples, 1);
timeInterval = [ time(1) time(end) ];

c1 = Color.pick(1);
c2 = Color.pick(2);

figure;
plot(time, fitness, 'Color', c1);
Plot.title('Log-posterior + constant');

figure;
plot(time, muu, 'Color', c1);
line(timeInterval, [ 1 1 ], 'Color', c2);
Plot.title('Mean of the QoI (normalized)');

figure;
plot(time, sigma2u, 'Color', c1);
line(timeInterval, [ 1 1 ], 'Color', c2);
Plot.title('Variance of the QoI (normalized)');

figure;
plot(time, sigma2e, 'Color', c1);
line(timeInterval, c.observations.noiseDeviation^2 * [ 1 1 ], 'Color', c2);
Plot.title('Variance of the noise');

trueZ = m.Z;

for i = 1:size(z, 2)
  figure;
  line(time, z(:, i), 'Color', c1);
  line(timeInterval, trueZ(i) * [ 1 1 ], 'Color', c2);
  Plot.title('Independent variable %d', i);
end
