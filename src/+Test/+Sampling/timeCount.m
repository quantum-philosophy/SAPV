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
  tests = { 'Sequential', 'Parallel' };

  function c = configure(i, j)
    c = Test.configure('forwardMethod', tests{j}, ...
      'timeCount', timeCount(i));
  end

  Utils.compare('Time count', ...
    experiments, tests, @configure, [], varargin{:});
end
