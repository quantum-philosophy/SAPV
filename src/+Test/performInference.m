function performInference(save)
  close all;
  setup;

  if nargin == 0, save = false; end

  c = Test.configure;
  m = Utils.measure(c);
  results = Utils.infer(c, m);
  results = Utils.process(c, m, results);

  if save, capture; end

  Utils.analyze(c, m, results);
  Utils.plot(c, m, results);

  if save, release; end
end
