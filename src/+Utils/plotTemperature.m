function plotTemperature(T, dt)
  [ processorCount, stepCount ] = size(T);

  if nargin > 1
    time = (0:(stepCount - 1)) * dt;
  else
    time = 0:(stepCount - 1);
  end

  figure;

  for i = 1:processorCount
    color = Color.pick(i);
    line(time, T(i, :), 'Color', color);
  end

  if nargin > 1
    Plot.label('Time, s', 'Temperature, C');
  else
    Plot.label('', 'Temperature, C');
  end

  Plot.limit(time, T);
end
