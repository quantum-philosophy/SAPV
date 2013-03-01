function plot(c, m, results)
  mRange = [ -3.5, 3.5 ] * c.process.deviation + c.process.mean;

  samples = results.samples;
  sampleCount = length(results.logPosterior);
  time = 1:sampleCount;

  %
  % The true quantity of interest.
  %
  plot(c.process, m.u);
  Colormap.data(m.u, mRange);
  Plot.title('QoI - True');
  commit('QoI - True.pdf');

  %
  % The mean of the inferred quantity of interest.
  %
  plot(c.process, results.mean.u);
  Colormap.data(results.mean.u, mRange);
  Plot.title('QoI - Inferred - Mean');
  commit('QoI - Inferred - Mean.pdf');

  %
  % Decision making.
  %
  decide(c.system.wafer, results.decision);
  Plot.title('Defect - Probability');
  commit('Defect - Probability.pdf');

  %
  % The error of the inferred quantity of interest.
  %
  error = abs(m.u - results.mean.u);
  dRange = [ 0, max([ error(:); results.deviation.u(:) ]) ];

  plot(c.process, error);
  Colormap.data(error, dRange, cool);
  Plot.title('QoI - Inferred - Absolute error (NRMSE %.2f%%)', ...
    results.error * 100);
  commit('QoI - Inferred - Absolute error.pdf');

  %
  % The deviation of the inferred quantity of interest.
  %
  plot(c.process, results.deviation.u);
  Colormap.data(results.deviation.u, dRange, cool);
  Plot.title('QoI - Inferred - Deviation');
  commit('QoI - Inferred - Deviation.pdf');

  %
  % The independent random variables, i.e., the z's.
  %
  dimensionCount = c.process.dimensionCount;

  cols = floor(sqrt(dimensionCount));
  rows = ceil(dimensionCount / cols);

  minZ = min([ samples.z(:); m.z(:) ]);
  maxZ = max([ samples.z(:); m.z(:) ]);

  Plot.figure();
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    trace([], samples.z(i, :), results.mean.z(i), ...
      results.deviation.z(i), m.z(i), i == dimensionCount);
    set(gca, 'XTick', [ time(1) time(end) ]);
    ylim([ minZ, maxZ ]);
  end
  Plot.name('QoI - Dummy parameters (z)');
  commit('QoI - Dummy parameters (z).pdf');

  % Plot.figure;
  % plotmatrix(samples.z(:, ...
  %   round(c.inference.burninRate * sampleCount):end)');
  % Plot.name('QoI - Dummy parameters (z) - Correlations');
  % commit('QoI - Dummy parameters (z) - Correlations.png', ...
  %   'format', 'png', 'orientation', 'portrait');

  %
  % The mean of the quantity of interest.
  %
  if ~c.inference.fixMuu
    Plot.figure;
    trace('QoI - Mean parameter (mu_u)', cumsum(samples.muu) ./ time, ...
      results.mean.muu, results.deviation.muu, c.process.mean);
    commit('QoI - Mean parameter (mu_u).pdf');
  end

  %
  % The standard deviation of the quantity of interest.
  %
  if ~c.inference.fixSigmau
    Plot.figure;
    trace('QoI - Deviation parameter (sigma_u)', ...
      cumsum(samples.sigmau) ./ time, results.mean.sigmau, ...
      results.deviation.sigmau, c.process.deviation);
    commit('QoI - Deviation parameter (sigma_u).pdf');
  end

  %
  % The standard deviation of the noise.
  %
  if ~c.inference.fixSigmae
    Plot.figure;
    trace('Noise - Deviation parameter (sigma_e)', ...
      cumsum(samples.sigmae) ./ time, results.mean.sigmae, ...
      results.deviation.sigmae, c.observations.deviation);
    commit('Noise - Deviation parameter (sigma_e).pdf');
  end

  %
  % The log-posterior.
  %
  Plot.figure;
  trace('Log-posterior', results.logPosterior);
  commit('Log-posterior.pdf');

  %
  % The acceptance rate.
  %
  Plot.figure;
  trace('Acceptance rate', cumsum(results.acceptance) ./ time);
  commit('Acceptance rate.pdf');

  %
  % The assessment of the proposal distribution.
  %
  if ~isempty(results.proposal.assessment)
    Plot.figure;
    Utils.plotProposalAssessment( ...
      results.proposal.theta, results.proposal.assessment);
    Plot.name('Proposal distribution');
    commit('Proposal distribution.pdf');
  end
end

function trace(name, samples, mean, deviation, true, legend)
  time = 1:length(samples);
  labels = {};

  c1 = Color.pick(1);

  line(time, samples, 'Color', c1);
  labels{end + 1} = 'Chain path';

  Plot.limit(time);

  if ~isempty(name), Plot.title(name); end

  for i = 1
    if nargin < 3, break; end

    c2 = Color.pick(4);

    line([ time(1) time(end) ], mean * [ 1 1 ], 'Color', c2);
    labels{end + 1} = 'Inferred';

    if nargin < 4, break; end

    line([ time(1) time(end) ], (mean - deviation) * [ 1 1 ], ...
      'Color', c2, 'LineStyle', '--');
    labels{end + 1} = 'Inferred minus deviation';

    line([ time(1) time(end) ], (mean + deviation) * [ 1 1 ], ...
      'Color', c2, 'LineStyle', '--');
    labels{end + 1} = 'Inferred plus deviation';

    if nargin < 5, break; end

    c3 = Color.pick(5);

    line([ time(1) time(end) ], true * [ 1 1 ], 'Color', c3);
    labels{end + 1} = 'True';
  end

  if nargin < 6, legend = nargin > 2; end
  if legend, Plot.legend(labels{:}); end
end

function decide(wafer, decision)
  c1 = 0.95 * [ 1, 1, 1 ];
  c2 =        [ 1, 0, 0 ];

  x = wafer.floorplan(:, 3);
  y = wafer.floorplan(:, 4);
  side = max(wafer.dieWidth, wafer.dieHeight);

  figure('Position', [ 100, 100, 60 + 600, 600 ]);

  for i = 1:wafer.dieCount
    h = draw(x(i), y(i), side, side);
    set(h, 'FaceColor', c1 + decision.probability(i) * (c2 - c1));
    set(h, 'EdgeColor', 0.15 * [ 1 1 1 ]);
  end

  lines = [];
  labels = {};

  %
  % Correctly classified as defective.
  %
  if ~isempty(decision.trueNegativeIndex)
    lines(end + 1) = line( ...
      x(decision.trueNegativeIndex) + side / 2, ...
      y(decision.trueNegativeIndex) + side / 2, ...
      'Color', 'k', 'LineStyle', 'None', 'Marker', 'x', 'MarkerSize', 20);
    labels{end + 1} = 'Correctly classified as defective (true negative)';
  end

  %
  % Misclassified as non-defective.
  %
  if ~isempty(decision.falsePositiveIndex)
    lines(end + 1) = line( ...
      x([ decision.falsePositiveIndex, decision.falsePositiveIndex ]) + side / 2, ...
      y([ decision.falsePositiveIndex, decision.falsePositiveIndex ]) + side / 2, ...
      'Color', 'k', 'LineStyle', 'None', 'Marker', '*', 'MarkerSize', 20);
    labels{end + 1} = 'Misclassified as non-defective (false positive)';
  end

  %
  % Misclassified as defective.
  %
  if ~isempty(decision.falseNegativeIndex)
    lines(end + 1) = line( ...
      x([ decision.falseNegativeIndex, decision.falseNegativeIndex ]) + side / 2, ...
      y([ decision.falseNegativeIndex, decision.falseNegativeIndex ]) + side / 2, ...
      'Color', 'k', 'LineStyle', 'None', 'Marker', 'o', 'MarkerSize', 20);
    labels{end + 1} = 'Misclassified as defective (false negative)';
  end

  legend(lines, labels);

  axis tight;

  Colormap.gradient(c1, c2);
  h = colorbar;
  set(h, 'YTickLabel', 0:0.1:1);

  %
  % Description.
  %
  annotation('textbox', [ 0.55 0.15 0.25 0.20 ], 'String', ...
    sprintf([ ...
      'Total dies: %d\n', ...
      'Defect dies: %d\n', ...
      'True positive: %d\n', ...
      'True negative: %d\n', ...
      'False positive: %d\n', ...
      'False negative: %d' ], ...
      wafer.dieCount, ...
      decision.trueCount, ...
      decision.truePositiveCount, ...
      decision.trueNegativeCount, ...
      decision.falsePositiveCount, ...
      decision.falseNegativeCount), ...
    'BackgroundColor', [ 1, 1, 1 ], 'FontSize', 16);
end

function h = draw(x, y, W, H)
  h = patch([ x, x, x + W, x + W ], [ y, y + H, y + H, y ], zeros(1, 4));
end
