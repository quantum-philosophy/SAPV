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

nRange = [ -3, 3 ];

plot(c.process, m.n);
Plot.title('Quantity of interest (true)');
colormap(Color.map(m.n, nRange));

if File.exist('inference.mat')
  load('inference.mat');
else
  %% Initialize the forward model.
  %
  model = Utils.forward(c, 'model', 'observed');

  %% Do the inference.
  %
  [ samples, fitness, acceptance ] = Utils.infer(c, m, model);

  save('inference.mat', 'samples', 'fitness', 'acceptance', '-v7.3');
end

sampleCount = size(samples, 1);

time = 1:sampleCount;
timeInterval = [ time(1) time(end) ];

c1 = Color.pick(1);
c2 = Color.pick(2);

figure;
plot(time, fitness, 'Color', c1);
Plot.title('Log-posterior + constant');
xlim(timeInterval);

z       = samples(:, 1:(end - 3))';
muu     = samples(:,    end - 2)';
sigma2u = samples(:,    end - 1)';
sigma2e = samples(:,    end - 0)';

inferredZ = mean(z(:, round(0.1 * sampleCount):end), 2);
[ ~, inferredN ] = c.process.compute(inferredZ);

plot(c.process, inferredN);
Plot.title('Quantity of interest (inferred)');
colormap(Color.map(inferredN, nRange));

fprintf('Error:\n');
fprintf('  Norm:  %.4e\n', Error.computeL2(m.n, inferredN));
fprintf('  MSE:   %.4e\n', Error.computeMSE(m.n, inferredN));
fprintf('  RMSE:  %.4e\n', Error.computeRMSE(m.n, inferredN));
fprintf('  NRMSE: %.4e\n', Error.computeNRMSE(m.n, inferredN));

Utils.plotChains(z, m.z);

muu     = cumsum(muu    ) ./ time;
sigma2u = cumsum(sigma2u) ./ time;
sigma2e = cumsum(sigma2e) ./ time;

figure;
plot(time, muu, 'Color', c1);
line(timeInterval, c.process.nominal * [ 1 1 ], 'Color', c2);
Plot.title('Mean of the QoI');

figure;
plot(time, sigma2u, 'Color', c1);
line(timeInterval, c.process.deviation^2 * [ 1 1 ], 'Color', c2);
Plot.title('Variance of the QoI');

figure;
plot(time, sigma2e, 'Color', c1);
line(timeInterval, c.observations.deviation^2 * [ 1 1 ], 'Color', c2);
Plot.title('Variance of the noise');
