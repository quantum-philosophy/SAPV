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
  tests = { 'Sequential', 'Parallel' };

  function c = configure(i, j)
    c = Test.configure('forwardMethod', tests{j}, ...
      'noiseDeviation', noiseDeviation(i));
  end

  Utils.compare('Noise deviation', ...
    experiments, tests, @configure, [], varargin{:});
end
