function compareDieCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  dieCount = [ 20, 40, 60, 80, 100, 120, 140, 160 ];

  experiments = {};
  for i = 1:length(dieCount)
    experiments{end + 1} = sprintf('%03d dies', dieCount(i));
  end

  %
  % Tests.
  %
  algorithms    = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];

  tests = algorithms;

  function [ c, m ] = prepare(i)
    [ c, m ] = Utils.prepare('dieCount', dieCount(i));
  end

  function [ c, m ] = adjust(i, j, c, m)
    c.inference.optimization.method = algorithms{j};
    c.inference.proposalRate = proposalRates(j);
  end

  Utils.compare('Die count', ...
    experiments, tests, @prepare, @adjust, [], varargin{:});
end
