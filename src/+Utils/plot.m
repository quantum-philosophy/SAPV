function plot(c, m, results, savePrefix)
  if nargin > 3 && ~isempty(savePrefix)
    save = @(name, varargin) ...
      Plot.save(File.join(savePrefix, name), varargin{:});
  else
    save = @(varargin) [];
  end

  newfigure = @() figure('Position', [ 100, 100, 600, 600 ]);

  nRange = [ -3, 3 ];
  samples = results.samples;
  sampleCount = c.inference.sampleCount;

  %
  % The true quantity of interest.
  %
  plot(c.process, m.n);
  colormap(Color.map(m.n, nRange));
  Plot.title('Quantity of interest (true)');
  save('QoI.pdf');

  %
  % The mean of the inferred quantity of interest.
  %
  plot(c.process, results.mean.n);
  colormap(Color.map(results.mean.n, nRange));
  Plot.title('The mean of the inferred QoI (NRMSE %.2f%%)', results.error * 100);
  save('QoI inferred.pdf');

  %
  % The deviation of the inferred quantity of interest.
  %
  plot(c.process, results.deviation.n);
  Plot.title('The standard deviation of the inferred QoI');
  save('QoI deviation.pdf');

  time = 1:sampleCount;

  %
  % The log-posterior.
  %
  newfigure();
  trace('Log-posterior', results.fitness);
  save('Log-posterior.pdf');

  %
  % The acceptance rate.
  %
  newfigure();
  trace('Acceptance rate', cumsum(results.acceptance) ./ time);
  save('Acceptance rate.pdf');

  %
  % The independent random variables, i.e., the z's.
  %
  dimensionCount = c.process.dimensionCount;

  cols = floor(sqrt(dimensionCount));
  rows = ceil(dimensionCount / cols);

  minZ = min([ samples.z(:); m.z(:) ]);
  maxZ = max([ samples.z(:); m.z(:) ]);

  newfigure();
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    trace([], samples.z(i, :), results.mean.z(i), ...
      results.deviation.z(i), m.z(i), i == dimensionCount);
    set(gca, 'XTick', [ time(1) time(end) ]);
    ylim([ minZ, maxZ ]);
  end
  Plot.name('The z''s');
  save('Z.pdf');

  newfigure();
  plotmatrix(samples.z(:, ...
    round(c.inference.burninRate * sampleCount):end)');
  Plot.name('Correlations of the z''s');
  save('Z correlations.png', 'format', 'png', 'orientation', 'portrait');

  if c.inference.assessProposal
    newfigure();
    Utils.plotProposalAssessment(results.theta, results.assessment);
    Plot.name('Proposal distribution at the posterior mode');
    save('Proposal distribution.pdf');
  end

  %
  % The mean of the quantity of interest.
  %
  if ~c.inference.fixMuu
    newfigure();
    trace('Mean of the QoI', cumsum(samples.muu) ./ time, ...
      results.mean.muu, results.deviation.muu, c.process.nominal);
    save('QoI mean.pdf');
  end

  %
  % The standard deviation of the quantity of interest.
  %
  if ~c.inference.fixSigmau
    newfigure();
    trace('Standard deviation of the QoI', cumsum(samples.sigmau) ./ time, ...
      results.mean.sigmau, results.deviation.sigmau, c.process.deviation);
    save('QoI deviation.pdf');
  end

  %
  % The standard deviation of the noise.
  %
  if ~c.inference.fixSigmae
    newfigure();
    trace('Standard deviation of the noise', cumsum(samples.sigmae) ./ time, ...
      results.mean.sigmae, results.deviation.sigmae, c.observations.deviation);
    save('Noise deviation.pdf');
  end
end

function trace(name, samples, mean, deviation, true, legend)
  time = 1:length(samples);
  labels = {};

  c1 = Color.pick(1);

  line(time, samples, 'Color', c1);
  labels{end + 1} = 'Chain';

  Plot.limit(time);

  if ~isempty(name), Plot.title(name); end

  for i = 1
    if nargin < 3, break; end

    c2 = Color.pick(4);

    line([ time(1) time(end) ], mean * [ 1 1 ], ...
      'Color', c2, 'LineWidth', 1);
    labels{end + 1} = 'Inferred';

    if nargin < 4, break; end

    line([ time(1) time(end) ], (mean - deviation) * [ 1 1 ], ...
      'Color', c2, 'LineStyle', '--', 'LineWidth', 1);
    labels{end + 1} = 'Inferred - deviation';

    line([ time(1) time(end) ], (mean + deviation) * [ 1 1 ], ...
      'Color', c2, 'LineStyle', '--', 'LineWidth', 1);
    labels{end + 1} = 'Inferred + deviation';

    if nargin < 5, break; end

    c3 = Color.pick(5);

    line([ time(1) time(end) ], true * [ 1 1 ], ...
      'Color', c3, 'LineWidth', 1);
    labels{end + 1} = 'True';
  end

  if nargin < 6, legend = nargin > 2; end
  if legend, Plot.legend(labels{:}); end
end
