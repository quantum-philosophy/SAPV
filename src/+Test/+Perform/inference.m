clear all;
close all;
setup;

if File.exist('rng.mat')
  load('rng.mat');
else
  r = rng;
  save('rng.mat', 'r', '-v7.3');
end

rng(r);

%% Configure the test case.
%
c = Test.configure;

%% Measure temperature profiles.
%
m = Test.measure(c);

%% Construct the surrogate model.
%
[ samples, fitness, acceptedCount ] = Test.infer(c, m);

muu     = samples(:, 1);
sigma2u = samples(:, 2);
sigma2e = samples(:, 3);
z       = samples(:, 4:end);

time = 1:size(samples, 1);

figure;
plot(time, fitness, 'Color', Color.pick(1));
Plot.title('Log-posterior + constant');

figure;
plot(time, muu, 'Color', Color.pick(1));
Plot.title('Mean of the QoI');

figure;
plot(time, sigma2u, 'Color', Color.pick(1));
Plot.title('Variance of the QoI');

figure;
plot(time, sigma2e, 'Color', Color.pick(1));
Plot.title('Variance of the noise');

figure;
for i = 1:size(z, 2)
  line(time, z(:, i), 'Color', Color.pick(i));
end
Plot.title('Independent variables');
