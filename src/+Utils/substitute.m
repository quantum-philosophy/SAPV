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
    options.inputCount = c.process.model.dimensionCount;
    options.nodeCount = c.surrogate.nodeCount;
    model = Utils.forward(c, 'model', 'observed');
    surrogate = Regression.GaussianProcess( ...
      'target', @(u) model.compute(norminv(u).'), options);
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
