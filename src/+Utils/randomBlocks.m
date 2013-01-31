function index = randomBlocks(IJ, count)
  I = IJ(:, 1);
  J = IJ(:, 2);

  rows = length(unique(I));
  cols = length(unique(J));

  index = zeros(1, count);

  while count > 0
    i = randi(rows);
    j = randi(cols);

    K = find(abs(I - i) + abs(J - j) == 0);

    if isempty(K), continue; end
    assert(isscalar(K));

    if ismember(K, index), continue; end

    index(count) = K;
    count = count - 1;
  end

  index = sort(index);
end
