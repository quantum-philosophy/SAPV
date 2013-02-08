function plot(this, F)
  wafer = this.wafer;

  W = wafer.dieFloorplan(:, 1);
  H = wafer.dieFloorplan(:, 2);
  X = wafer.dieFloorplan(:, 3);
  Y = wafer.dieFloorplan(:, 4);

  dieW = max(X + W);
  dieH = max(Y + H);

  dieX = dieW / 2;
  dieY = dieH / 2;

  D = zeros(0, 3);

  for i = 1:wafer.dieCount
    processorX = wafer.floorplan(i, 1) + X + W / 2;
    processorY = wafer.floorplan(i, 2) + Y + H / 2;

    D = [ D; processorX, processorY, F(:, i) ];
  end

  x = D(:, 1);
  y = D(:, 2);
  z = D(:, 3);

  X = linspace(min(x), max(x), 50);
  Y = linspace(min(y), max(y), 50);

  [ X, Y ] = meshgrid(X, Y);

  Z = griddata(x, y, z, X, Y);

  figure('Position', [ 100 100 (600 + 60) 600 ]);

  surfc(X, Y, Z, 'EdgeColor','None', 'LineStyle', 'None', ...
    'FaceLighting', 'Phong');
  colorbar;
  axis tight;
  view(2);

  return;

  hold on;
  plot3(x, y, z, '.', 'Color', 'k', 'MarkerSize', 0.01);
end
