function compareDieMeasurements(varargin)
  close all;
  setup;

  %
  % Experiments.
  %
  timeCount = [ 20, 40, 60, 80, 100 ];

  experiments = {};
  for i = 1:length(timeCount)
    experiments{end + 1} = sprintf('%03d times', timeCount(i));
  end

  %
  % Tests.
  %
  algorithms    = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];

  tests = algorithms;

  function [ c, m ] = prepare(i)
    [ c, m ] = Utils.prepare('timeCount', timeCount(i));
  end

  function [ c, m ] = adjust(c, m, j)
    c.inference.optimization.method = algorithms{j};
    c.inference.proposalRate = proposalRates(j);
  end

  Utils.compare('Time measurements', ...
    experiments, tests, @prepare, @adjust, varargin{:});
end
