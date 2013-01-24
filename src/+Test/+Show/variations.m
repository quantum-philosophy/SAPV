clear all;
setup;

c = Test.configure;
p = c.process;

U = p.model.sample;

plot(p.model, U);
colormap(Color.map(U, [ -3, 3 ]));
Plot.title('Quantity of interest (normalized)');
