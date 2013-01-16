clear all;
setup;

c = Test.configure;

Lnom = c.Lnom;
Ldev = c.Ldev;

L = Lnom + Ldev * c.process.sample;

plot(c.process, L);
colormap(Color.map(L, [ Lnom - 3 * Ldev, Lnom + 3 * Ldev ]));
Plot.title('Channel length');
