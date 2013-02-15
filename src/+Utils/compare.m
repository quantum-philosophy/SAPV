function compare(name, experiments, tests, configure, perform, save)
  close all;
  setup;

  if ~exist('configure', 'var') || isempty(configure)
    configure = @(i) Utils.configure;
  end

  if ~exist('perform', 'var') || isempty(perform)
    perform = @(i, j, c, m) Utils.perform(c, m);
  end

  if ~exist('save', 'var'), save = false; end
  if save, capture([], name); end

  experimentCount = length(experiments);
  testCount = length(tests);

  results = cell(experimentCount, testCount);

  for i = 1:experimentCount
    if save, capture(experiments{i}); end

    for j = 1:testCount
      c = configure(i, j);
      m = Utils.measure(c);
      results{i, j} = perform(i, j, c, m);

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
      time(i, j) = results{i, j}.time.optimization + ...
        results{i, j}.time.sampling;
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

  if experimentCount > 1
    %% Timing.
    %
    Plot.figure;
    h = bar(1:experimentCount, time / 60);
    Bar.colorize(h);
    Plot.title('Computational time');
    Plot.label('', 'Time, m');
    Plot.tick(1:experimentCount, experiments);
    Plot.legend(tests);
    commit('Computational time.pdf');

    %% Accuracy.
    %
    Plot.figure;
    h = bar(1:experimentCount, error * 100);
    Bar.colorize(h);
    Plot.title('Normalized RMSE');
    Plot.label('', 'NRMSE, %');
    Plot.tick(1:experimentCount, experiments);
    Plot.legend(tests);
    commit('Normalized RMSE.pdf');
  end

  if save, release; end
end
