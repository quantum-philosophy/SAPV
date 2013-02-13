function index = optimizedBlocks(IJ, count)
  %
  % The algorithm is not optimized and, therefore, a bit time consuming.
  % Cache it!
  %

  filename = File.temporal( ...
    sprintf('optimizedBlocks_%s.mat', DataHash({ IJ, count })));

  if File.exist(filename)
    load(filename);
    return
  end

  I = IJ(:, 1);
  J = IJ(:, 2);

  [ I1, I2 ] = meshgrid(I);
  [ J1, J2 ] = meshgrid(J);

  D = sqrt((I1 - I2).^2 + (J1 - J2).^2);

  P = [];
  A = 1:length(I);

  for i = 1:count
    score = zeros(1, length(A));
    for j = 1:length(A)
      for k = 1:length(A)
        if k == j, continue; end
        score(j) = score(j) + min(D(A(k), [ P, A(j) ]));
      end
    end
    [ ~, k ] = sort(score);
    P(end + 1) = A(k(1));
    A(k(1)) = [];
  end

  index = sort(P);

  save(filename, 'index', '-v7.3');
end
