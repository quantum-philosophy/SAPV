clear all;
setup;

c = Test.configure;

[ u, n, z ] = c.process.sample;

plot(c.process, n);
colormap(Color.map(z, [ -3, 3 ]));
Plot.title('Quantity of interest (normalized)');
