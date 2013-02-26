function decision = decide(c, m, u)
  uLimit = c.process.mean - 2 * c.process.deviation;
  pLimit = 0.9;

  decision.probability = sum(min(u, [], 1) < uLimit, 3) / size(u, 3);

  I = 1:c.system.wafer.dieCount;
  T = find(min(m.u, [], 1) < uLimit);
  D = find(decision.probability > pLimit);

  decision.trueIndex          = T;
  decision.falsePositiveIndex = setdiff(T, D); % Type I
  decision.falseNegativeIndex = setdiff(setdiff(I, T), setdiff(I, D)); % Type II
  decision.truePositiveIndex  = intersect(setdiff(I, T), setdiff(I, D));
  decision.trueNegativeIndex  = intersect(D, T);

  decision.trueCount          = length(decision.trueIndex);
  decision.falsePositiveCount = length(decision.falsePositiveIndex);
  decision.falseNegativeCount = length(decision.falseNegativeIndex);
  decision.truePositiveCount  = length(decision.truePositiveIndex);
  decision.trueNegativeCount  = length(decision.trueNegativeIndex);
end
