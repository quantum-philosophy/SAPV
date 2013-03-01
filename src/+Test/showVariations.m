close all;
setup;

c = Test.configure;

plot(c.system.wafer, c.observations.dieIndex);

sampleCount = [ 1e1, 1e2, 1e3, 1e4, 1e5 ];

u = zeros(c.system.wafer.processorCount, ...
  c.system.wafer.dieCount, max(sampleCount));

for i = 1:max(sampleCount)
  u(:, :, i) = c.process.sample;
end

expectation = zeros(1, length(sampleCount));
deviation = zeros(1, length(sampleCount));

for i = 1:length(sampleCount)
  e = mean(u(:, :, 1:sampleCount(i)), 3) / c.process.mean;
  d = std(u(:, :, 1:sampleCount(i)), [], 3) / c.process.deviation;
  expectation(i) = abs(mean(e(:)) - 1);
  deviation(i) = abs(mean(d(:)) - 1);
end

figure;
loglog(sampleCount, expectation, 'Color', Color.pick);
Plot.title('Normalized error of mean');

figure;
loglog(sampleCount, deviation, 'Color', Color.pick);
Plot.title('Normalized error of deviation');
