function [ mapping, inverseMapping ] = construct(this, wafer, options)
  kernel = options.kernel;
  threshold = options.get('threshold', this.threshold);

  F = wafer.floorplan;
  DF = wafer.dieFloorplan;

  W = DF(:, 1);
  H = DF(:, 2);
  X = DF(:, 3) + W / 2;
  Y = DF(:, 4) + H / 2;

  X = bsxfun(@plus, repmat(X, 1, wafer.dieCount), F(:, 1).');
  Y = bsxfun(@plus, repmat(Y, 1, wafer.dieCount), F(:, 2).');

  X = X(:);
  Y = Y(:);

  totalCount = length(X);

  [ X1, X2 ] = meshgrid(X);
  [ Y1, Y2 ] = meshgrid(Y);

  C = kernel([ X1(:).'; Y1(:).' ], [ X2(:).'; Y2(:).' ]);
  C = reshape(C, [ totalCount, totalCount ]);

  [ mapping, inverseMapping ] = computeReduced(C, threshold);
end

function [ mapping, inverseMapping ] = computeFull(C)
  [ V, L ] = eig(C);
  mapping = V * sqrt(L);
  inverseMapping = diag(1 ./ sqrt(diag(L))) * V.';
end

function [ mapping, inverseMapping ] = computeReduced(C, threshold)
  totalCount = size(C, 1);

  dimensionCount = 10;

  options.issym = 1;
  options.isreal = 1;
  options.maxit = 1e3;
  options.disp = 0;
  options.v0 = ones(totalCount, 1);

  L = eigs(C, dimensionCount);
  L = sort(L, 'descend');

  Y = [ ones(dimensionCount, 1), - (1:dimensionCount)' ];
  a = Y \ log(sqrt(L));
  L = exp(a(1)) .* (exp(a(2)) .^ (-(1:totalCount)'));

  dimensionCount = Utils.chooseSignificant(L, threshold);

  [ V, L, flag ] = eigs(C, dimensionCount, 'lm', options);
  if ~(flag == 0), warning('eigs did not converge.'); end

  [ dimensionCount, L, I ] = Utils.chooseSignificant(diag(L), threshold);
  V = V(:, I);

  mapping = V * diag(sqrt(L));
  inverseMapping = diag(1 ./ sqrt(L)) * V.';
end
