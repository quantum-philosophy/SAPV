function plotChains(z, trueZ)
  dimensionCount = length(trueZ);

  cols = floor(sqrt(dimensionCount));
  rows = ceil(dimensionCount / cols);

  time = 1:size(z, 2);
  timeInterval = [ time(1) time(end) ];

  c1 = Color.pick(1);
  c2 = Color.pick(2);

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    line(time, z(i, :), 'Color', c1);
    line(timeInterval, trueZ(i) * [ 1 1 ], 'Color', c2);
    set(gca, 'XTick', timeInterval);
  end

  z = bsxfun(@rdivide, cumsum(z, 2), time);

  figure;
  for i = 1:dimensionCount
    subplot(rows, cols, i);
    line(time, z(i, :), 'Color', c1);
    line(timeInterval, trueZ(i) * [ 1 1 ], 'Color', c2);
    set(gca, 'XTick', timeInterval);
  end
end
