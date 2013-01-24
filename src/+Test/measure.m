function m = measure(c)
  m = Options;

  %
  % Generate temperature profiles for all the dies.
  %
  hs = HotSpot.Batch('floorplan', c.system.floorplan, ...
    'config', c.temperature.configuration, 'line', c.temperature.line);

  m.U = c.process.Unom + c.process.Udev * c.process.model.sample;
  T = hs.compute(c.power.Pdyn, ...
    'leakage', c.leakage.model, 'parameters', m.U(:));
  m.T = reshape(T, [ c.system.processorCount, ...
    c.power.stepCount, c.system.wafer.dieCount ]);

  %
  % Choose spatial locations.
  %
  m.dieIndex = nonrandomCircle(c.system.wafer.radius, ...
    c.system.wafer.floorplan(:, 1) + c.system.wafer.dieWidth / 2, ...
    c.system.wafer.floorplan(:, 2) + c.system.wafer.dieHeight / 2, ...
    c.observations.dieCount);

  %
  % Choose temporal locations.
  %
  m.timeIndex = nonrandomLine(c.power.stepCount, c.observations.timeCount);

  %
  % Generate some noise.
  %
  noise = c.observations.noiseDeviation * ...
    randn(c.system.processorCount, c.observations.timeCount, ...
      c.observations.dieCount);

  %
  % Thin the data.
  %
  m.Tmeas = m.T(:, m.timeIndex, m.dieIndex);

  %
  % Add the noise.
  %
  m.Tmeas = m.Tmeas + noise;
end

function index = randomLine(maximalCount, count)
  index = randperm(maximalCount);
  index = sort(index(1:count));
end

function index = nonrandomLine(maximalCount, count)
  count = count + 2;
  delta = maximalCount / (count - 1);
  index = floor((0:(count - 1)) * delta + 1);
  index = index(2:(end - 1));
end

function index = randomCircle(radius, X, Y, count)
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
