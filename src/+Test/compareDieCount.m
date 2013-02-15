function compareDieCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  dieCount = [ 1, 10, 20, 40, 80, 160 ];

  experiments = {};
  for i = 1:length(dieCount)
    experiments{end + 1} = sprintf('%d dies', dieCount(i));
  end

  %
  % Tests.
  %
  algorithms    = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];

  tests = algorithms;

  function c = configure(i)
    c = Test.configure('dieCount', dieCount(i));
  end

  function c = adjust(i, j, c)
    c.inference.optimization.method = algorithms{j};
    c.inference.proposalRate = proposalRates(j);
  end

  Utils.compare('Die count', ...
    experiments, tests, @configure, @adjust, [], varargin{:});
end
