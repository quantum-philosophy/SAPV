function compareNoiseDeviation(varargin)
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
  algorithms    = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];

  tests = algorithms;

  function c = configure(i)
    c = Test.configure('noiseDeviation', noiseDeviation(i));
  end

  function c = adjust(i, j, c)
    c.inference.optimization.method = algorithms{j};
    c.inference.proposalRate = proposalRates(j);
  end

  Utils.compare('Noise deviation', ...
    experiments, tests, @configure, @adjust, [], varargin{:});
end
