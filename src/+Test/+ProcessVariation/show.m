clear all;
setup;

c = Test.configure;

Lnom = c.leakage.Lnom;
Ldev = 0.05 * Lnom;
L = Lnom + Ldev * c.process.sample;

plot(c.process, L);
