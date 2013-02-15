function dieCount(varargin)
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
  tests = { 'none', 'fminunc', 'csminwel' };
  proposalScale = [ 0.05, 0.50, 0.50 ];

  function c = configure(i, j)
    c = Test.configure('dieCount', dieCount(i));
    c.inference.optimization.method = tests{j};
    c.inference.proposal.scale = proposalScale(j);
  end

  Utils.compare('Die count', ...
    experiments, tests, @configure, [], varargin{:});
end
