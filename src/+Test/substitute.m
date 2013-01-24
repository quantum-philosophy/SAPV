function surrogate = substitute(c, m, nodes, responses)
  %
  % Configure the surrogate construction algorithm.
  %
  kernel = Options( ...
    'compute', @correlate, ...
    'parameters', [ 1, 1 ], ...
    'lowerBound', [ 1e-3, 1e-3 ], ...
    'upperBound', [ 2, 10 ]);

  options = Options;

  options.kernel = kernel;
  options.inputCount = c.dimensionCount;
  options.outputCount = c.system.processorCount * ...
    c.observations.timeCount * c.observations.dieCount;
  options.nodeCount = c.surrogate.nodeCount;

  if nargin > 2
    %
    % We already have some data; just process it.
    %
    options.nodes = nodes;
    options.responses = responses;

    surrogate = Regression.GaussianProcess(options);
  else
    %
    % Since no data provided, we need to sample ourselves.
    %
    Pdyn = c.power.Pdyn;
    timeIndex = m.timeIndex;
    leakage = c.leakage.model;

    Unom = c.process.Unom;
    Udev = c.process.Udev;
    Umap = c.process.model.constrainMapping(m.dieIndex);

    hotspot = HotSpot.Batch('floorplan', c.system.floorplan, ...
      'config', c.temperature.configuration, 'line', c.temperature.line);

    surrogate = Regression.GaussianProcess( ...
      'target', @(u) hotspot.compute(Pdyn, timeIndex, leakage, ...
        Unom + Udev * Umap * norminv(u).'), options);
  end
end

function [ K, dK ] = correlate(x, y, params)
  s = params(1); % Standard deviation
  l = params(2); % Length scale

  n = sum((x - y).^2, 1);
  e = exp(-n / (2 * l^2));
  K = s^2 * e;

  if nargout == 1, return; end % Derivatives?

  dK = [ 2 * s * e; l^(-3) * K .* n ];
end
