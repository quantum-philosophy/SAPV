clear all;
setup;

c = Test.configure;

mc = HotSpot.MonteCarlo('floorplan', c.floorplan, 'config', c.hotspotConfig, ...
  'line', c.hotspotLine);
[ T, L ] = mc.compute(c.Pdyn, 'leakage', c.leakage, ...
  'process', c.process, 'verbose', true);

plot(c.process, L);
