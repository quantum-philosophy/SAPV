function compare(name, experiments, tests, prepare, adjust, save)
  close all;
  setup;

  if ~exist('save', 'var'), save = false; end
  if save, capture([], name); end

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
  time = zeros(experimentCount, testCount);
  error = zeros(experimentCount, testCount);

  for i = 1:experimentCount
    fprintf('Experimental setup "%s".\n', experiments{i});

    %% Header.
    %
    fprintf('%15s', 'Test');
    for j = 1:testCount
      fprintf(' %15s', tests{j});
    end
    fprintf('\n');

    %% Timing.
    %
    fprintf('%15s', 'Time, m');
    for j = 1:testCount
      time(i, j) = results{i, j}.time;
      fprintf(' %15.2f', time(i, j) / 60);
    end
    fprintf('\n');

    %% Accuracy.
    %
    fprintf('%15s', 'NRMSE, %');
    for j = 1:testCount
      error(i, j) = results{i, j}.error;
      fprintf(' %15.2f', error(i, j) * 100);
    end

    fprintf('\n\n');
  end

  %% Timing.
  %
  Plot.figure;
  for i = 1:testCount
    line(1:experimentCount, time(:, i) / 60, ...
      'Color', Color.pick(i), 'Marker', 'o');
  end
  Plot.title('Computational time');
  Plot.label('', 'Time, m');
  Plot.tick(1:experimentCount, experiments);
  Plot.limit([ 0.9, experimentCount + 0.1 ]);
  Plot.legend(tests);
  commit('Computational time.pdf');

  %% Accuracy.
  %
  Plot.figure;
  for i = 1:testCount
    line(1:experimentCount, error(:, i) * 100, ...
      'Color', Color.pick(i), 'Marker', 'o');
  end
  Plot.title('Normalized RMSE');
  Plot.label('', 'NRMSE, %');
  Plot.tick(1:experimentCount, experiments);
  Plot.limit([ 0.9, experimentCount + 0.1 ]);
  Plot.legend(tests);
  commit('Normalized RMSE.pdf');

  if save, release; end
end
