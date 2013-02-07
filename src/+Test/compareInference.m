function compareInference(save)
  setup;

  if nargin == 0, save = false; end

  if save
    c = clock;
    prefix = sprintf('%04d-%02d-%02d %02d-%02d-%02d', ...
      c(1), c(2), c(3), c(4), c(5), round(c(6)));
    mkdir(prefix);
    file = fopen(File.join(prefix, 'report.txt'), 'w');
    printf = @(varargin) fprintf(file, varargin{:});
  else
    printf = @fprintf;
  end

  platformDimensions = [ 2, 4, 8, 16, 32 ];
  platformCount = length(platformDimensions);

  methodNames   = { 'none', 'fminunc', 'csminwel' };
  proposalRates = [   0.05,      0.50,       0.50 ];
  methodCount = length(methodNames);

  results = cell(platformCount, methodCount);

  for i = 1:platformCount
    processorCount = platformDimensions(i);
    [ c, m ] = Utils.prepare(processorCount);

    if save
      platformPrefix = sprintf('%03d', processorCount);
      mkdir(File.join(prefix, platformPrefix));
    end

    for j = 1:methodCount
      c.inference.optimization.method = methodNames{j};
      c.inference.proposalRate = proposalRates(j);
      results{i, j} = Utils.perform(c, m);
      if save
        overallPrefix = File.join(prefix, platformPrefix, methodNames{j});
        mkdir(overallPrefix);
        Utils.plot(c, m, results{i, j}, overallPrefix);
        close all;
      end
    end

    fprintf('Platform with %3d processing elements.\n', processorCount);
    report(@fprintf, methodNames, results(i, :));
  end

  %
  % Summarize everything.
  %
  for i = 1:platformCount
    processorCount = platformDimensions(i);
    printf('Platform with %3d processing elements.\n', processorCount);
    report(printf, methodNames, results(i, :));
    printf('\n');
  end

  if save, fclose(file); end
end

function report(printf, names, results)
  methodCount = length(results);

  %% Header.
  %
  printf('%15s', 'Optimization');
  for i = 1:methodCount
    printf(' %15s', names{i});
  end
  printf('\n');

  %% Timing.
  %
  printf('%15s', 'Time, m');
  for i = 1:methodCount
    printf(' %15.2f', results{i}.time / 60);
  end
  printf('\n');

  %% Accuracy.
  %
  printf('%15s', 'NRMSE, %');
  for i = 1:methodCount
    printf(' %15.2f', results{i}.error * 100);
  end
  printf('\n');
end
