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

if File.exist('inference.mat')
  load('inference.mat');
else
  %% Initialize the forward model.
  %
  model = Utils.forward(c, 'model', 'observed');

  %% Do the inference.
  %
  [ samples, fitness, acceptCount ] = Utils.infer( ...
    'data', m.Tmeas, 'model', model, 'verbose', true, c.inference);

  save('inference.mat', 'samples', 'fitness', 'acceptCount', '-v7.3');
end

z       = samples(:, 1:(end - 3));
muu     = samples(:,    end - 2);
sigma2u = samples(:,    end - 1);
sigma2e = samples(:,    end - 0);

inferredZ = mean(z((end - 1e3):end, :), 1)';
[ ~, inferredN ] = c.process.compute(inferredZ);

nRange = [ -3, 3 ];

plot(c.process, m.n);
Plot.title('Quantity of interest (true)');
colormap(Color.map(m.n, nRange));

plot(c.process, inferredN);
Plot.title('Quantity of interest (inferred)');
colormap(Color.map(inferredN, nRange));

return;

time = 1:size(samples, 1);

timeInterval = [ time(1) time(end) ];

z       = bsxfun(@rdivide, cumsum(z, 1)', time);
muu     = cumsum(muu    )' ./ time;
sigma2u = cumsum(sigma2u)' ./ time;
sigma2e = cumsum(sigma2e)' ./ time;

c1 = Color.pick(1);
c2 = Color.pick(2);

trueZ = m.z;

for i = 1:size(z, 1)
  figure;
  line(time, z(i, :), 'Color', c1);
  line(timeInterval, trueZ(i) * [ 1 1 ], 'Color', c2);
  Plot.title('Independent variable %d', i);
end

figure;
plot(time, fitness, 'Color', c1);
Plot.title('Log-posterior + constant');

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
