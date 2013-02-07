clear all;
close all;
setup;

[ c, m ] = Utils.prepare;
results = Utils.perform(c, m);
Utils.analyze(c, m, results);
Utils.plot(c, m, results);
