clear all;
setup;

c = Test.configure;

L = c.Lnom + c.Ldev * c.process.sample;

plot(c.process, L);
