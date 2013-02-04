clear all;
close all;
setup;

[ c, m ] = Utils.prepare;
[ results, samples ] = Utils.perform(c, m);
Utils.plot(c, m, results, samples);
