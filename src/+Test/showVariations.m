close all;
setup;

c = Test.configure;

plot(c.system.wafer, c.observations.dieIndex);

[ u, n, z ] = c.process.sample;

plot(c.process, n);
Colormap.data(z, [ -3.5, 3.5 ]);
Plot.title('Quantity of interest (normalized)');
