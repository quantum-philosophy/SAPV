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
  tests = { 'Matlab', 'Sims' };

  function c = configure(i, j)
    c = Test.configure('noiseDeviation', noiseDeviation(i));
    c.optimization.method = tests{j};
  end

  Utils.compare('Noise deviation', ...
    experiments, tests, @configure, [], varargin{:});
end
