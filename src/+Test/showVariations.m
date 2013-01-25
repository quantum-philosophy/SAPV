clear all;
close all;
setup;

c = Test.configure;

U = c.process.model.sample;

plot(c.process.model, U);
colormap(Color.map(U, [ -3, 3 ]));
Plot.title('Quantity of interest (normalized)');
