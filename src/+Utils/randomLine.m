function index = randomLine(maximalCount, count)
  index = randperm(maximalCount);
  index = sort(index(1:count));
end
