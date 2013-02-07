clear all;
close all;
setup;

[ c, m ] = Utils.prepare;
results = Utils.perform(c, m);
Utils.plot(c, m, results);
