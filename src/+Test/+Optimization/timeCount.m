function timeCount(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  timeCount = [ 1, 10, 20, 40, 80, 160 ];

  experiments = {};
  for i = 1:length(timeCount)
    experiments{end + 1} = sprintf('%d times', timeCount(i));
  end

  %
  % Tests.
  %
  tests = { 'Matlab', 'Sims' };
  proposalScale = [ 0.60, 0.60 ];

  function c = configure(i, j)
    c = Test.configure('timeCount', timeCount(i));
    c.optimization.method = tests{j};
    c.proposal.scale = proposalScale(j);
  end

  Utils.compare('Time count', ...
    experiments, tests, @configure, [], varargin{:});
end
