clear all;
setup;

c = Test.configure;
p = c.process;

L = p.Lnom + p.Ldev * p.model.sample;

plot(p.model, L);
colormap(Color.map(L, [ p.Lnom - 3 * p.Ldev, p.Lnom + 3 * p.Ldev ]));
Plot.title('Channel length');
