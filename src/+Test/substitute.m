function surrogate = substitute(c, m)
  filename = File.temporal(sprintf('Surrogate_%s.mat', ...
    DataHash({ c.Pdyn, Utils.toString(c.leakage), ...
      Utils.toString(c.process), m.spaceMeasurementIndex, ...
      m.timeMeasurementIndex })));

  if File.exist(filename)
    fprintf('Surrogate: using cached data in "%s"...\n', filename);
    load(filename);
  else
    fprintf('Surrogate: construction...\n');

    hs = HotSpot.Surrogate('floorplan', c.floorplan, ...
      'config', c.hotspotConfig, 'line', c.hotspotLine);

    tic;
    surrogate = hs.compute(c.Pdyn, ...
      'leakage', c.leakage, 'process', c.process, ...
      'spaceMeasurementIndex', m.spaceMeasurementIndex, ...
      'timeMeasurementIndex', m.timeMeasurementIndex, ...
      'surrogateOptions', c.surrogateOptions);
    time = toc;

    save(filename, 'surrogate', 'time', '-v7.3');
  end

  fprintf('Surrogate: construction time %.2f s.\n', time);
end
