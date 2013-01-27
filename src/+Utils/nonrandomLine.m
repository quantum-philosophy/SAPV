function index = nonrandomLine(maximalCount, count)
  count = count + 2;
  delta = maximalCount / (count - 1);
  index = floor((0:(count - 1)) * delta + 1);
  index = index(2:(end - 1));
end
