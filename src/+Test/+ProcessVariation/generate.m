setup;

c = Test.configure;

Pdyn = c.Pdyn;
hs = c.hotspot;

[ T, Pleak ] = hs.computeWithLeakage(Pdyn, c.leakage);
