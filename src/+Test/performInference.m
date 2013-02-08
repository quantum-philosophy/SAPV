function performInference(save)
  close all;
  setup;

  if nargin == 0, save = false; end

  if save
    prefix = Utils.makeTimeStamp;
    mkdir(prefix);
  else
    prefix = [];
  end

  [ c, m ] = Utils.prepare;
  results = Utils.perform(c, m);
  Utils.analyze(c, m, results);
  Utils.plot(c, m, results, prefix);
end
