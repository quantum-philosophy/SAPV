clear all;
setup;

%
% Configure the test case.
%
c = Test.configure;

%
% Measure temperature profiles.
%
m = Test.measure(c);

%
% Construct the surrogate model.
%
s = Test.substitute(c, m);
