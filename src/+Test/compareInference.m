function compareInference(save)
  close all;
  setup;

  if nargin == 0, save = false; end
  if save, capture; end

  platformDimensions = [ 2, 4, 8, 16, 32 ];
  platformCount = length(platformDimensions);

  methodNames   = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];
  methodCount = length(methodNames);

  results = cell(platformCount, methodCount);

  for i = 1:platformCount
    processorCount = platformDimensions(i);
    [ c, m ] = Utils.prepare(processorCount);

    if save, capture(sprintf('%03d', processorCount)); end

    for j = 1:methodCount
      c.inference.optimization.method = methodNames{j};
      c.inference.proposalRate = proposalRates(j);
      results{i, j} = Utils.perform(c, m);

      if save
        capture(methodNames{j});

        Utils.analyze(c, m, results{i, j});
        Utils.plot(c, m, results{i, j});
        close all;

        release;
      end
    end

    if save, release; end
  end

  %
  % Summarize everything.
  %
  for i = 1:platformCount
    processorCount = platformDimensions(i);
    fprintf('Platform with %3d processing elements.\n', processorCount);

    methodCount = length(results);

    %% Header.
    %
    fprintf('%15s', 'Optimization');
    for i = 1:methodCount
      fprintf(' %15s', methodNames{i});
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

    fprintf('\n\n');
  end

  if save, release; end
end
