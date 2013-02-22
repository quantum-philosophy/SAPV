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

  function c = configure(i, j)
    c = Test.configure('processorCount', processorCount(i));
  end

  Utils.compare('Processor count', ...
    experiments, {}, @configure, [], varargin{:});
end
