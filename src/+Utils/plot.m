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
  Plot.title('True quantity of interest');
  save('QoI true.pdf');

  %
  % The inferred quantity of interest.
  %
  plot(c.process, results.n);
  colormap(Color.map(results.n, nRange));
  Plot.title('Inferred quantity of interest (NRMSE %.2f%%)', results.error * 100);
  save('QoI inferred.pdf');

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
    trace([], samples.z(i, :), results.z(i), m.z(i));
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
      results.muu, c.process.nominal);
    save('QoI mean.pdf');
  end

  %
  % The standard deviation of the quantity of interest.
  %
  if ~c.inference.fixSigmau
    newfigure();
    trace('Standard deviation of the QoI', cumsum(samples.sigmau) ./ time, ...
      results.sigmau, c.process.deviation);
    save('QoI deviation.pdf');
  end

  %
  % The standard deviation of the noise.
  %
  if ~c.inference.fixSigmae
    newfigure();
    trace('Standard deviation of the noise', cumsum(samples.sigmae) ./ time, ...
      results.sigmae, c.observations.deviation);
    save('Noise deviation.pdf');
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
