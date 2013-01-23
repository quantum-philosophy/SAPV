clear all;
setup;

c = Test.configure;
p = c.process;

U = p.Unom + p.Udev * p.model.sample;

plot(p.model, U);
colormap(Color.map(U, [ p.Unom - 3 * p.Udev, p.Unom + 3 * p.Udev ]));
Plot.title('Quantity of interest');
