function compareSampleCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  sampleCount = [ 1e2, 1e3, 1e4, 1e5 ];

  experiments = {};
  for i = 1:length(sampleCount)
    experiments{end + 1} = sprintf('%d samples', sampleCount(i));
  end

  %
  % Tests.
  %
  tests = { 'none', 'fminunc', 'csminwel' };
  proposalScale = [ 0.05, 0.50, 0.50 ];

  function c = configure(i, j)
    c = Test.configure('sampleCount', max(sampleCount));
    c.inference.optimization.method = tests{j};
    c.inference.proposal.scale = proposalScale(j);
  end

  function results = perform(i, j, c, m)
    results = Utils.perform(c, m, sampleCount(i));
  end

  Utils.compare('Sample count', ...
    experiments, tests, @configure, @perform, varargin{:});
end
