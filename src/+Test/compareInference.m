function compareInference(platformDimensions)
  clear all;
  setup;

  if nargin == 0, platformDimensions = [ 2 ]; end
  platformCount = length(platformDimensions);

  methodNames   = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];
  methodCount = length(methodNames);

  results = cell(platformCount, methodCount);

  for i = 1:platformCount
    processorCount = platformDimensions(i);
    [ c, m ] = Utils.prepare(processorCount);

    for j = 1:methodCount
      c.inference.optimization.method = methodNames{j};
      c.inference.proposalRate = proposalRates(j);
      results{i, j} = Utils.perform(c, m);
    end

    fprintf('Platform with %3d processing elements.\n', processorCount);
    reportResults(methodNames, results(i, :));
  end

  if platformCount == 1, return; end

  %
  % Summarize everything.
  %
  for i = 1:platformCount
    processorCount = platformDimensions(i);
    fprintf('Platform with %3d processing elements.\n', processorCount);
    reportResults(methodName, results(i, :));
  end
end

function reportResults(names, results)
  methodCount = length(results);

  %% Header.
  %
  fprintf('%15s', 'Optimization');
  for i = 1:methodCount
    fprintf(' %15s', names{i});
  end
  fprintf('\n');

  %% Timing.
  %
  fprintf('%15s', 'Time, m');
  for i = 1:methodCount
    fprintf(' %15.2f', results{i}.time / 60);
  end
  fprintf('\n');

  %% Accuracy.
  %
  fprintf('%15s', 'NRMSE, %');
  for i = 1:methodCount
    fprintf(' %15.2f', results{i}.error * 100);
  end
  fprintf('\n');
end
