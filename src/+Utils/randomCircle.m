function index = randomCircle(radius, X, Y, count)
  warning('Not random at all!');

  index = zeros(1, count);

  for i = 1:count
    while true
      r = radius * sqrt(rand);
      phi = 2 * pi * rand;
      x = r * cos(phi);
      y = r * sin(phi);
      [ ~, I ] = sort(sqrt((X - x).^2 + (Y - y).^2));
      if ismember(I(1), index), continue; end
      index(i) = I(1);
      break;
    end
  end

  index = sort(index);
end
