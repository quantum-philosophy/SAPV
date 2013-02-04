function plot(c, m, results, samples)
  sampleCount = samples.count;

  time = 1:sampleCount;
  timeInterval = [ time(1) time(end) ];

  c1 = Color.pick(1);
  c2 = Color.pick(2);

  figure;
  plot(time, samples.fitness, 'Color', c1);
  Plot.title('Log-posterior + constant');
  xlim(timeInterval);

  nRange = [ -3, 3 ];

  plot(c.process, m.n);
  Plot.title('True QoI');
  colormap(Color.map(m.n, nRange));

  plot(c.process, results.n);
  Plot.title('Inferred QoI (error %.4f)', results.error);
  colormap(Color.map(results.n, nRange));

  dimensionCount = c.process.dimensionCount;

  cols = floor(sqrt(dimensionCount));
  rows = ceil(dimensionCount / cols);

  time = 1:sampleCount;
  timeInterval = [ time(1) time(end) ];

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    line(time, samples.z(i, :), 'Color', c1);
    line(timeInterval, results.z(i) * [ 1 1 ], 'Color', c1);
    line(timeInterval, m.z(i) * [ 1 1 ], 'Color', c2);
    set(gca, 'XTick', timeInterval);
    xlim(timeInterval);
  end

  z = bsxfun(@rdivide, cumsum(samples.z, 2), time);

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    line(time, z(i, :), 'Color', c1);
    line(timeInterval, m.z(i) * [ 1 1 ], 'Color', c2);
    set(gca, 'XTick', timeInterval);
    xlim(timeInterval);
  end

  if ~isempty(samples.muu)
    figure;
    muu = cumsum(samples.muu) ./ time;
    plot(time, muu, 'Color', c1);
    line(timeInterval, c.process.nominal * [ 1 1 ], 'Color', c2);
    Plot.title('Mean of the QoI');
  end

  if ~isempty(samples.sigma2u)
    figure;
    sigma2u = cumsum(samples.sigma2u) ./ time;
    plot(time, sigma2u, 'Color', c1);
    line(timeInterval, c.process.deviation^2 * [ 1 1 ], 'Color', c2);
    Plot.title('Variance of the QoI');
  end

  if ~isempty(samples.sigma2e)
    figure;
    sigma2e = cumsum(samples.sigma2e) ./ time;
    plot(time, sigma2e, 'Color', c1);
    line(timeInterval, c.observations.deviation^2 * [ 1 1 ], 'Color', c2);
    Plot.title('Variance of the noise');
  end
end
