clear all;
close all;
setup;

Utils.fixRNG;

%% Configure the test case.
%
c = Test.configure;

plot(c.system.wafer, c.observations.dieIndex);

%% Measure temperature profiles.
%
m = Utils.measure(c);

if File.exist('inference.mat')
  load('inference.mat');
else
  %% Initialize the forward model.
  %
  model = Utils.forward(c, 'model', 'observed');

  %% Do the inference.
  %
  [ samples, fitness, acceptCount ] = Utils.infer(c, m, model);

  save('inference.mat', 'samples', 'fitness', 'acceptCount', '-v7.3');
end

time = 1:size(samples, 1);
timeInterval = [ time(1) time(end) ];

c1 = Color.pick(1);
c2 = Color.pick(2);

figure;
plot(time, fitness, 'Color', c1);
Plot.title('Log-posterior + constant');

z       = samples(:, 1:(end - 3))';
muu     = samples(:,    end - 2)';
sigma2u = samples(:,    end - 1)';
sigma2e = samples(:,    end - 0)';

inferredZ = mean(z(:, (end - 1e3):end), 2);
[ ~, inferredN ] = c.process.compute(inferredZ);

nRange = [ -3, 3 ];

plot(c.process, m.n);
Plot.title('Quantity of interest (true)');
colormap(Color.map(m.n, nRange));

plot(c.process, inferredN);
Plot.title('Quantity of interest (inferred)');
colormap(Color.map(inferredN, nRange));

Utils.plotChains(z, m.z);

return;

muu     = cumsum(muu    ) ./ time;
sigma2u = cumsum(sigma2u) ./ time;
sigma2e = cumsum(sigma2e) ./ time;

figure;
plot(time, muu, 'Color', c1);
line(timeInterval, c.process.nominal * [ 1 1 ], 'Color', c2);
Plot.title('Mean of the QoI (normalized)');

figure;
plot(time, sigma2u, 'Color', c1);
line(timeInterval, c.process.deviation^2 * [ 1 1 ], 'Color', c2);
Plot.title('Variance of the QoI (normalized)');

figure;
plot(time, sigma2e, 'Color', c1);
line(timeInterval, c.observations.deviation^2 * [ 1 1 ], 'Color', c2);
Plot.title('Variance of the noise');
