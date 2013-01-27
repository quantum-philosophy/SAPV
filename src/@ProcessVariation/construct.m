function mapping = construct(this, wafer, options)
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

  count = length(X);

  I = Utils.constructPairIndex(count);
  C = kernel( ...
    [ X(I(:, 1)).'; Y(I(:, 1)).' ], ...
    [ X(I(:, 2)).'; Y(I(:, 2)).' ]);
  C = Utils.symmetrizePairIndex(C, I);

  switch lower(options.get('method', 'svd'))
  case 'eig'
    mapping = decomposeEIG(C, threshold);
  case 'svd'
    mapping = decomposeSVD(C, threshold);
  otherwise
    assert(false);
  end
end

function mapping = decomposeEIG(C, threshold)
  [ V, L ] = eig(C); L = diag(L);

  [ ~, L, I ] = Utils.chooseSignificant(L, threshold);
  V = V(:, I);

  mapping = V * diag(sqrt(L));
end

function mapping = decomposeSVD(C, threshold)
  [ V, L ] = pcacov(C);

  [ ~, L, I ] = Utils.chooseSignificant(L, threshold);
  V = V(:, I);

  mapping = V * diag(sqrt(L));
end
