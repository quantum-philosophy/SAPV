function [ expansion, mapping ] = construct(this, wafer, options)
  domainBoundary = sqrt((wafer.width / 2)^2 + (wafer.height / 2)^2);
  correlationLength = options.get('correlationScale', 1) * domainBoundary;
  threshold = options.get('threshold', this.threshold);

  F = wafer.floorplan;
  DF = wafer.dieFloorplan;

  W = DF(:, 1);
  H = DF(:, 2);
  X = DF(:, 3) + W / 2;
  Y = DF(:, 4) + H / 2;

  dieCount = wafer.dieCount;
  processorCount = wafer.processorCount;
  totalCount = dieCount * processorCount;

  X = bsxfun(@plus, repmat(X, 1, dieCount), F(:, 1).');
  Y = bsxfun(@plus, repmat(Y, 1, dieCount), F(:, 2).');

  switch lower(options.get('method', 'analytic'))
  case 'analytic'
    expansion = KarhunenLoeve.OrnsteinUhlenbeck( ...
      'domainBoundary', domainBoundary, ...
      'correlationLength', correlationLength, ...
      'threshold', threshold);
    mapping = postprocessKarhunenLoeve(X, Y, expansion, threshold);
  case 'numeric'
    kernel = @(s, t) exp(-abs(s - t) / correlationLength);
    expansion = KarhunenLoeve.Fredholm( ...
      'domainBoundary', domainBoundary, ...
      'correlationLength', correlationLength, ...
      'threshold', threshold, 'kernel', kernel);
    mapping = postprocessKarhunenLoeve(X, Y, expansion, threshold);
  case 'discrete'
    kernel = @(s, t) exp(-sum(abs(s - t), 1) / correlationLength);
    [ X1, X2 ] = meshgrid(X(:));
    [ Y1, Y2 ] = meshgrid(Y(:));
    C = kernel(transpose([ X1(:) Y1(:) ]), transpose([ X2(:) Y2(:) ]));
    C = reshape(C, [ totalCount, totalCount ]);
    mapping = computeReduced(C, threshold);
  otherwise
    assert(false);
  end
end

function mapping = postprocessKarhunenLoeve(X, Y, expansion, threshold)
  X = X(:);
  Y = Y(:);

  pointCount = length(X);

  values = expansion.values;
  dimension = expansion.dimensionCount;

  L = zeros(0, 3);
  for i = 1:dimension
    for j = 1:dimension
      L(end + 1, :) = [ i, j, values(i) * values(j) ];
    end
  end

  [ ~, I ] = sort(L(:, 3), 'descend');
  L = L(I, :);

  dimension = Utils.chooseSignificant(L(:, 3), threshold);

  mapping = zeros(pointCount, dimension);
  for k = 1:dimension
    i = L(k, 1); j = L(k, 2); l = L(k, 3);
    fi = expansion.functions{i};
    fj = expansion.functions{j};
    mapping(:, k) = sqrt(l) * fi(X) .* fj(Y);
  end
end

function M = computeFull(C)
  [ V, L ] = eig(C);
  M = V * sqrt(L);
end

function M = computeReduced(C, threshold)
  d = size(C, 1);

  n = 10;

  o.issym = 1;
  o.isreal = 1;
  o.maxit = 1e3;
  o.disp = 0;
  o.v0 = ones(d, 1);

  L = eigs(C, n);
  L = sort(L, 'descend');

  Y = [ ones(n, 1), - (1:n)' ];
  a = Y \ log(sqrt(L));
  L = exp(a(1)) .* (exp(a(2)) .^ (-(1:d)'));

  n = Utils.chooseSignificant(L, threshold);

  [ V, L, flag ] = eigs(C, n, 'lm', o);
  if ~(flag == 0), warning('eigs did not converge.'); end

  [ n, L, I ] = Utils.chooseSignificant(diag(L), threshold);
  V = V(:, I);

  M = V * sqrt(diag(L));
end
