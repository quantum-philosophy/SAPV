function compareProcessorCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  processorCount = [ 2 ];

  experiments = {};
  for i = 1:length(processorCount)
    experiments{end + 1} = sprintf('%d processors', processorCount(i));
  end

  %
  % Tests.
  %
  algorithms    = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];

  tests = algorithms;

  function c = configure(i)
    c = Test.configure('processorCount', processorCount(i));
  end

  function c = adjust(i, j, c)
    c.inference.optimization.method = algorithms{j};
    c.inference.proposalRate = proposalRates(j);
  end

  Utils.compare('Processor count', ...
    experiments, tests, @configure, @adjust, [], varargin{:});
end
