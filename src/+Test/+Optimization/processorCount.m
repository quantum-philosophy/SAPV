function processorCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  processorCount = [ 2, 4, 8, 16, 32 ];

  experiments = {};
  for i = 1:length(processorCount)
    experiments{end + 1} = sprintf('%d processors', processorCount(i));
  end

  %
  % Tests.
  %
  tests = { 'Matlab', 'Sims' };

  function c = configure(i, j)
    c = Test.configure('processorCount', processorCount(i));
    c.optimization.method = tests{j};
  end

  Utils.compare('Processor count', ...
    experiments, tests, @configure, [], varargin{:});
end
