function [ expansion, mapping ] = construct(this, wafer, options)
  domainBoundary = sqrt((wafer.width / 2)^2 + (wafer.height / 2)^2);
  correlationLength = options.get('correlationScale', 1) * domainBoundary;
  threshold = options.get('threshold', this.threshold);
  kernel = @(s, t) exp(-abs(s - t) / correlationLength);

  expansion = KarhunenLoeve.OrnsteinUhlenbeck( ...
    'domainBoundary', domainBoundary, ...
    'correlationLength', correlationLength, ...
    'threshold', threshold, 'kernel', kernel);

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

  function computeGridBased
    [ X1, X2 ] = meshgrid(X(:));
    [ Y1, Y2 ] = meshgrid(Y(:));
    C = expansion.calculate( ...
      transpose([ X1(:) Y1(:) ]), ...
      transpose([ X2(:) Y2(:) ]));
    C = reshape(C, [ totalCount, totalCount ]);
    mapping = computeReduced(C, threshold);
  end

  function computeKarhunenLoeveBased
    X = X(:);
    Y = Y(:);

    values = expansion.values;
    dimension = expansion.dimensionCount;

    L = zeros(0, 3);
    for i = 1:dimension
      for j = i:dimension
        L(end + 1, :) = [ i, j, values(i) * values(j) ];
      end
    end

    [ ~, I ] = sort(L(:, 3), 'descend');
    L = L(I, :);

    dimension = sum(L(:, 3) ./ cumsum(L(:, 3)) < (1 - threshold)) + 1;

    mapping = zeros(dieCount * processorCount, dimension);
    for i = 1:dimension
      f1 = expansion.functions{L(i, 1)};
      f2 = expansion.functions{L(i, 2)};
      if L(i, 1) == L(i, 2)
        mapping(:, i) = sqrt(L(i, 3)) * f1(X) .* f2(Y);
      else
        %
        % Off diagonal elements are counted twice.
        %
        mapping(:, i) = sqrt(L(i, 3)) * f1(X) .* f2(Y) / sqrt(2);
      end
    end
  end

  computeKarhunenLoeveBased;
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
  Lest = exp(a(1)) .* (exp(a(2)) .^ (-(1:d)'));

  n = sum(cumsum(Lest) < threshold * sum(Lest)) + 1;

  [ V, L, flag ] = eigs(C, n, 'lm', o);
  if ~(flag == 0), warning('eigs did not converge.'); end

  L = abs(diag(L));
  [ L, I ] = sort(L, 'descend');
  V = V(:, I);

  M = V * sqrt(diag(L));
end
