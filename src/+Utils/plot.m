function plot(c, m, results, samples, savePrefix)
  if nargin > 4
    save = @(name, varargin) ...
      Plot.save(File.join(savePrefix, name), varargin{:});
  else
    save = @(varargin) [];
  end

  sampleCount = samples.count;

  time = 1:sampleCount;
  timeInterval = [ time(1) time(end) ];

  c1 = Color.pick(1);
  c2 = Color.pick(2);

  %
  % The log-posterior.
  %
  figure;
  plot(time, samples.fitness, 'Color', c1);
  Plot.title('Log-posterior + constant');
  xlim(timeInterval);
  save('log-posterior.pdf');

  nRange = [ -3, 3 ];

  %
  % The true quantity of interest.
  %
  plot(c.process, m.n);
  Plot.title('True QoI');
  colormap(Color.map(m.n, nRange));
  save('u true.pdf');

  %
  % The inferred quantity of interest.
  %
  plot(c.process, results.n);
  Plot.title('Inferred QoI (error %.2f%%)', results.error * 100);
  colormap(Color.map(results.n, nRange));
  save('u inferred.pdf');

  %
  % The independent random variables, i.e., the z's.
  %
  dimensionCount = c.process.dimensionCount;

  cols = floor(sqrt(dimensionCount));
  rows = ceil(dimensionCount / cols);

  time = 1:sampleCount;
  timeInterval = [ time(1) time(end) ];

  z = samples.z;

  figure;
  plotmatrix(z(:, round(c.inference.burninRate * sampleCount):end)');
  save('z scatter plot.png', 'format', 'png');

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    line(time, z(i, :), 'Color', c1);
    line(timeInterval, results.z(i) * [ 1 1 ], 'Color', c1);
    line(timeInterval, m.z(i) * [ 1 1 ], 'Color', c2);
    set(gca, 'XTick', timeInterval);
    xlim(timeInterval);
  end
  save('z.pdf');

  z = bsxfun(@rdivide, cumsum(z, 2), time);

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    line(time, z(i, :), 'Color', c1);
    line(timeInterval, m.z(i) * [ 1 1 ], 'Color', c2);
    set(gca, 'XTick', timeInterval);
    xlim(timeInterval);
  end
  save('z average.pdf');

  %
  % The mean of the quantity of interest.
  %
  if ~isempty(samples.muu)
    figure;
    muu = cumsum(samples.muu) ./ time;
    plot(time, muu, 'Color', c1);
    line(timeInterval, c.process.nominal * [ 1 1 ], 'Color', c2);
    Plot.title('Mean of the QoI');
    save('muu.pdf');
  end

  %
  % The variance of the quantity of interest.
  %
  if ~isempty(samples.sigma2u)
    figure;
    sigma2u = cumsum(samples.sigma2u) ./ time;
    plot(time, sigma2u, 'Color', c1);
    line(timeInterval, c.process.deviation^2 * [ 1 1 ], 'Color', c2);
    Plot.title('Variance of the QoI');
    save('sigma2u.pdf');
  end

  %
  % The variance of the noise.
  %
  if ~isempty(samples.sigma2e)
    figure;
    sigma2e = cumsum(samples.sigma2e) ./ time;
    plot(time, sigma2e, 'Color', c1);
    line(timeInterval, c.observations.deviation^2 * [ 1 1 ], 'Color', c2);
    Plot.title('Variance of the noise');
    save('sigma2e.pdf');
  end
end
