function plot(c, m, results)
  newfigure = @() figure('Position', [ 100, 100, 600, 600 ]);

  nRange = [ -3, 3 ];
  samples = results.samples;
  sampleCount = c.inference.sampleCount;
  time = 1:sampleCount;

  %
  % The true quantity of interest.
  %
  plot(c.process, m.n);
  colormap(Color.map(m.n, nRange));
  Plot.title('True QoI');
  commit('QoI - True.pdf');

  %
  % The mean of the inferred quantity of interest.
  %
  plot(c.process, results.mean.n);
  colormap(Color.map(results.mean.n, nRange));
  Plot.title('Mean of the inferred QoI (NRMSE %.2f%%)', results.error * 100);
  commit('QoI - Inferred - Mean.pdf');

  %
  % The deviation of the inferred quantity of interest.
  %
  plot(c.process, results.deviation.n);
  Plot.title('Standard deviation of the inferred QoI');
  commit('QoI - Inferred - Deviation.pdf');

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
  commit('QoI - Dummy parameters (z).pdf');

  % newfigure();
  % plotmatrix(samples.z(:, ...
  %   round(c.inference.burninRate * sampleCount):end)');
  % Plot.name('Correlations of the dummy parameters');
  % commit('QoI - Dummy parameters (z) - Correlations.png', ...
  %   'format', 'png', 'orientation', 'portrait');

  %
  % The mean of the quantity of interest.
  %
  if ~c.inference.fixMuu
    newfigure();
    trace('The mean parameter of the QoI', cumsum(samples.muu) ./ time, ...
      results.mean.muu, results.deviation.muu, c.process.nominal);
    commit('QoI - Mean parameter (mu_u).pdf');
  end

  %
  % The standard deviation of the quantity of interest.
  %
  if ~c.inference.fixSigmau
    newfigure();
    trace('The standard deviation parameter of the QoI', cumsum(samples.sigmau) ./ time, ...
      results.mean.sigmau, results.deviation.sigmau, c.process.deviation);
    commit('QoI - Deviation parameter (sigma_u).pdf');
  end

  %
  % The standard deviation of the noise.
  %
  if ~c.inference.fixSigmae
    newfigure();
    trace('Standard deviation of the noise', cumsum(samples.sigmae) ./ time, ...
      results.mean.sigmae, results.deviation.sigmae, c.observations.deviation);
    commit('Noise - Deviation parameter (sigma_e).pdf');
  end

  %
  % The log-posterior.
  %
  newfigure();
  trace('Log-posterior', results.fitness);
  commit('Log-posterior.pdf');

  %
  % The acceptance rate.
  %
  newfigure();
  trace('Acceptance rate', cumsum(results.acceptance) ./ time);
  commit('Acceptance rate.pdf');

  %
  % The assessment of the proposal distribution.
  %
  if c.inference.assessProposal
    newfigure();
    Utils.plotProposalAssessment(results.theta, results.assessment);
    Plot.name('Proposal distribution at the posterior mode');
    commit('Proposal distribution.pdf');
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
