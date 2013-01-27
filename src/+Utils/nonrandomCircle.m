function index = nonrandomCircle(radius, X, Y, count)
  index = zeros(1, count);

  phi = 2 * pi / (count - 1) * (1:(count - 1));
  y = [ 0, radius * cos(phi) / 2 ];
  x = [ 0, radius * sin(phi) / 2 ];

  for i = 1:count
    [ ~, I ] = sort(sqrt((X - x(i)).^2 + (Y - y(i)).^2));
    index(i) = I(1);
  end

  index = sort(index);
end
