function noiseDeviation(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  noiseDeviation = [ 0, 0.5, 1, 2 ];

  experiments = {};
  for i = 1:length(noiseDeviation)
    experiments{end + 1} = [ num2str(noiseDeviation(i)), ' noise' ];
  end

  %
  % Tests.
  %
  tests = { 'None', 'Matlab', 'Sims' };
  proposalScale = [ 0.05, 0.50, 0.50 ];

  function c = configure(i, j)
    c = Test.configure('noiseDeviation', noiseDeviation(i));
    c.optimization.method = tests{j};
    c.proposal.scale = proposalScale(j);
  end

  Utils.compare('Noise deviation', ...
    experiments, tests, @configure, [], varargin{:});
end