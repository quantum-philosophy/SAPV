function index = nonrandomBlocks(IJ, count)
  I = IJ(:, 1);
  J = IJ(:, 2);

  rows = length(unique(I));
  cols = length(unique(J));

  countI = floor(sqrt(count));
  countJ = ceil(sqrt(count));
  
  II = round((1:countI) * rows / (countI + 1));
  JJ = round((1:countJ) * cols / (countJ + 1));

  index = zeros(1, 0);

  for i = II
    for j = JJ
      K = find(abs(I - i) + abs(J - j) == 0);

      if isempty(K), continue; end
      assert(isscalar(K));

      if ismember(K, index), continue; end

      index(end + 1) = K;
    end
  end

  index = sort(index);
end
