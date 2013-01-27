function index = semirandomCircle(radius, X, Y, count)
  index = zeros(1, count);

  [ ~, I ] = sort(sqrt(X.^2 + Y.^2));
  index(1) = I(1);

  for i = 2:count
    while true
      phi = 2 * pi * rand;
      x = radius * cos(phi) / 2;
      y = radius * sin(phi) / 2;
      [ ~, I ] = sort(sqrt((X - x).^2 + (Y - y).^2));
      if ismember(I(1), index), continue; end
      index(i) = I(1);
      break;
    end
  end

  index = sort(index);
end
