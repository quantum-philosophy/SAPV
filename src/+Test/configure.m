function c = configure
  c = Options;

  %
  % System
  %
  c.system = Options;
  c.system.processorCount = 2;

  taskCount = 40;
  tgffConfig = File.join('+Test', 'Assets', ...
    sprintf('%03d_%03d.tgff', c.system.processorCount, taskCount));

  c.system.floorplan = File.join('+Test', 'Assets', ...
    sprintf('%03d.flp', c.system.processorCount));

  [ platform, application ] = parseTGFF(tgffConfig);
  c.system.wafer = Wafer('floorplan', c.system.floorplan, ...
    'columns', 20, 'rows', 40);

  schedule = Schedule.Dense(platform, application);

  %
  % Temperature
  %
  c.samplingInterval = 1e-3; % s

  c.temperature = Options;
  c.temperature.configuration = ...
    File.join('+Test', 'Assets', 'hotspot.config');
  c.temperature.line = ...
    sprintf('sampling_intvl %e', c.samplingInterval);

  %
  % Dynamic power
  %
  power = DynamicPower(c.samplingInterval);

  c.power = Options;
  c.power.Pdyn = power.compute(schedule);
  c.power.stepCount = size(c.power.Pdyn, 2);

  %
  % Leakage power
  %
  c.leakage = Options;
  c.leakage.database = File.join('+Test', 'Assets', 'inverter_45nm.leak');
  c.leakage.order = [ 1, 2 ];
  c.leakage.scale = [ 1, 0.7, 0; 1, 1, 1 ];
  c.leakage.model = LeakagePower(c.power.Pdyn, ...
    'filename', c.leakage.database, 'order', c.leakage.order, ...
    'scale', c.leakage.scale);

  %
  % Process variation
  %
  c.process = Options;
  c.process.Lnom = c.leakage.model.Lnom;
  c.process.Ldev = 0.05 * c.leakage.model.Lnom;

  eta = 0.70;
  lse = 0.10 * c.system.wafer.radius;
  lou = 0.10 * c.system.wafer.radius;

  function K = kernel(s, t)
    %
    % Squared exponential kernel.
    %
    Kse = eta * exp(-sum((s - t).^2, 1) / lse^2);

    %
    % Ornstein-Uhlenbeck kernel.
    %
    rs = sqrt(sum(s.^2, 1));
    rt = sqrt(sum(t.^2, 1));
    Kou = (1 - eta) * exp(-abs(rs - rt) / lou);

    K = Kse + Kou;
  end

  filename = File.temporal([ 'ProcessVariation_', ...
    DataHash({ eta, lse, lou }), '.mat' ]);

  if File.exist(filename)
    load(filename);
  else
    process = ProcessVariation(c.system.wafer, 'kernel', @kernel);
    save(filename, 'process', '-v7.3');
  end

  c.process.model = process;

  %
  % Observations
  %
  c.observations = Options;
  c.observations.noiseDeviation = 1;
  c.observations.dieCount = 10;
  c.observations.timeCount = 10;

  c.observations.dieIndex = nonrandomCircle( ...
    c.system.wafer.radius, ...
    c.system.wafer.floorplan(:, 1) + c.system.wafer.dieWidth / 2, ...
    c.system.wafer.floorplan(:, 2) + c.system.wafer.dieHeight / 2, ...
    c.observations.dieCount);

  c.observations.timeIndex = nonrandomLine( ...
    c.power.stepCount, c.observations.timeCount);

  %
  % Surrogate
  %
  c.surrogate = Options;
  c.surrogate.nodeCount = 1e3;

  %
  % Inference.
  %
  % NOTE: Ideal scenario for now.
  %
  c.inference = Options;
  c.inference.sampleCount = 1e4;

  c.inference.proposalRate = 0.05;

  % The prior on the mean of the QoI.
  c.inference.mu0 = 1; % Normalized!
  c.inference.sigma0 = 0.01;

  % The prior on the variance of the QoI.
  %
  % As if from...
  c.inference.nuu = 2;
  % ... observations we concluded that it should be...
  c.inference.tauu = 1; % Normalized!

  % The prior on the variance of the noise.
  %
  % As if from...
  c.inference.nue = 2;
  % ... observations we concluded that it should be...
  c.inference.taue = c.observations.noiseDeviation;
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
