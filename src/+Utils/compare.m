function compare(experiments, tests, prepare, adjust, save)
  close all;
  setup;

  if ~exist('save', 'var'), save = false; end
  if save, capture; end

  experimentCount = length(experiments);
  testCount = length(tests);

  results = cell(experimentCount, testCount);

  for i = 1:experimentCount
    [ c, m ] = prepare(i);

    if save, capture(experiments{i}); end

    for j = 1:testCount
      adjust(c, m, j);
      results{i, j} = Utils.perform(c, m);

      if save
        capture(tests{j});

        Utils.analyze(c, m, results{i, j});
        Utils.plot(c, m, results{i, j});
        close all;

        release;
      end
    end

    if save, release; end
  end

  %
  % Summarize!
  %
  for i = 1:experimentCount
    fprintf('Experimental setup "%s".\n', experiments{i});

    %% Header.
    %
    fprintf('%15s', 'Test');
    for i = 1:testCount
      fprintf(' %15s', tests{i});
    end
    fprintf('\n');

    %% Timing.
    %
    fprintf('%15s', 'Time, m');
    for i = 1:testCount
      fprintf(' %15.2f', results{i}.time / 60);
    end
    fprintf('\n');

    %% Accuracy.
    %
    fprintf('%15s', 'NRMSE, %');
    for i = 1:testCount
      fprintf(' %15.2f', results{i}.error * 100);
    end

    fprintf('\n\n');
  end

  if save, release; end
end
