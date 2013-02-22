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

  function c = configure(i, j)
    c = Test.configure('dieCount', dieCount(i));
  end

  Utils.compare('Die count', ...
    experiments, {}, @configure, [], varargin{:});
end
