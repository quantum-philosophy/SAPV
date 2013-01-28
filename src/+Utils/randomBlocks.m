function index = randomBlocks(X, Y, W, H, count)
  L = min(X);
  R = max(X) + W;

  B = min(Y);
  T = max(Y) + H;

  rows = round((T - B) / H);
  cols = round((R - L) / W);

  index = zeros(1, count);

  while count > 0
    i = randi(rows);
    j = randi(cols);

    y = (i - 1) * H + B;
    x = (j - 1) * W + L;

    I = find(abs(X - x) + abs(Y - y) == 0);

    if isempty(I), continue; end

    assert(isscalar(I));

    if ismember(I, index), continue; end

    index(count) = I;
    count = count - 1;
  end

  index = sort(index);
end
