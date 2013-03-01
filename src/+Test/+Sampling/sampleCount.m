function sampleCount(varargin)
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
  tests = { 'Sequential', 'Parallel' };

  function c = configure(i, j)
    c = Test.configure('forwardMethod', tests{j}, ...
      'sampleCount', max(sampleCount));
  end

  function results = perform(i, j, c, m)
    results = Utils.infer(c, m);
    results = Utils.process(c, m, results, sampleCount(i));
  end

  Utils.compare('Sample count', ...
    experiments, tests, @configure, @perform, varargin{:});
end
