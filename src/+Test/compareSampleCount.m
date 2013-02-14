function compareSampleCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  sampleCount = [ 1e2, 1e3, 1e4, 1e5 ];

  experiments = {};
  for i = 1:length(sampleCount)
    experiments{end + 1} = sprintf('%06d samples', sampleCount(i));
  end

  %
  % Tests.
  %
  algorithms    = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];

  tests = algorithms;

  function [ c, m ] = prepare(i)
    [ c, m ] = Utils.prepare('sampleCount', max(sampleCount));
  end

  function [ c, m ] = adjust(i, j, c, m)
    c.inference.optimization.method = algorithms{j};
    c.inference.proposalRate = proposalRates(j);
  end

  function results = perform(i, j, c, m)
    results = Utils.perform(c, m, sampleCount(i));
  end

  Utils.compare('Sample count', ...
    experiments, tests, @prepare, @adjust, @perform, varargin{:});
end
