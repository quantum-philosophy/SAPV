function plot(c, m, results, savePrefix)
  if nargin > 3
    save = @(name, varargin) ...
      Plot.save(File.join(savePrefix, name), varargin{:});
  else
    save = @(varargin) [];
  end

  nRange = [ -3, 3 ];
  samples = results.samples;
  sampleCount = c.inference.sampleCount;

  %
  % The true quantity of interest.
  %
  plot(c.process, m.n);
  colormap(Color.map(m.n, nRange));
  Plot.title('True QoI');
  save('u true.pdf');

  %
  % The inferred quantity of interest.
  %
  plot(c.process, results.n);
  colormap(Color.map(results.n, nRange));
  Plot.title('Inferred QoI (error %.2f%%)', results.error * 100);
  save('u inferred.pdf');

  time = 1:sampleCount;

  %
  % The log-posterior.
  %
  figure;
  trace('Log-posterior + constant', results.fitness);
  save('log-posterior.pdf');

  %
  % The acceptance rate.
  %
  figure;
  trace('Acceptance rate', cumsum(results.acceptance) ./ time);
  save('acceptance.pdf');

  %
  % The independent random variables, i.e., the z's.
  %
  dimensionCount = c.process.dimensionCount;

  cols = floor(sqrt(dimensionCount));
  rows = ceil(dimensionCount / cols);

  minZ = min([ samples.z(:); m.z(:) ]);
  maxZ = max([ samples.z(:); m.z(:) ]);

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    trace([], samples.z(i, :), results.z(i), m.z(i));
    set(gca, 'XTick', [ time(1) time(end) ]);
    ylim([ minZ, maxZ ]);
  end
  save('z.pdf');

  figure;
  plotmatrix(samples.z(:, ...
    round(c.inference.burninRate * sampleCount):end)');
  save('z scatter plot.png', 'format', 'png');

  %
  % The mean of the quantity of interest.
  %
  if ~c.inference.fixMuu
    figure;
    trace('Mean of the QoI', cumsum(samples.muu) ./ time, ...
      results.muu, c.process.nominal);
    save('muu.pdf');
  end

  %
  % The variance of the quantity of interest.
  %
  if ~c.inference.fixSigma2u
    figure;
    trace('Variance of the QoI', cumsum(samples.sigma2u) ./ time, ...
      results.sigma2u, c.process.deviation^2);
    save('sigma2u.pdf');
  end

  %
  % The variance of the noise.
  %
  if ~c.inference.fixSigma2e
    figure;
    trace('Variance of the noise', cumsum(samples.sigma2e) ./ time, ...
      results.sigma2e, c.observations.deviation^2);
    save('sigma2e.pdf');
  end
end

function trace(name, samples, inferredValue, trueValue)
  time = 1:length(samples);

  plot(time, samples, 'Color', Color.pick(1));
  Plot.limit(time);

  if ~isempty(name), Plot.title(name); end

  if nargin < 3, return; end

  line([ time(1) time(end) ], inferredValue * [ 1 1 ], 'Color', 'k');

  if nargin < 4, return; end

  line([ time(1) time(end) ], trueValue * [ 1 1 ], ...
    'Color', 'k', 'LineStyle', '--');
end
