function [ expansion, mapping ] = construct(this, wafer, options)
  domain = sqrt((wafer.width / 2)^2 + (wafer.height / 2)^2);

  expansion = KarhunenLoeve.OrnsteinUhlenbeck( ...
    'domainBoundary', domain, ...
    'correlationLength', domain, ...
    'threshold', options.get('threshold', this.threshold));

  dimension = length(expansion.values);
  this.dimension = dimension;

  W = wafer.dieFloorplan(:, 1);
  H = wafer.dieFloorplan(:, 2);
  X = wafer.dieFloorplan(:, 3);
  Y = wafer.dieFloorplan(:, 4);

  dieW = max(X + W);
  dieH = max(Y + H);

  dieX = dieW / 2;
  dieY = dieH / 2;

  mapping = zeros(wafer.processorCount, dimension, wafer.dieCount);

  for i = 1:wafer.dieCount
    offset = [ ...
      wafer.floorplan(i, 1) + dieW / 2, ...
      wafer.floorplan(i, 2) + dieH / 2 ];

    processorX = X + W / 2 - dieX - offset(1);
    processorY = Y + H / 2 - dieY - offset(2);

    for j = 1:wafer.processorCount
      distance = sqrt(processorX(j)^2 + processorY(j)^2);
      for k = 1:dimension
        mappin(j, k, i) = sqrt(expansion.values(k)) * ...
          expansion.functions{k}(distance);
      end
    end
  end
end
