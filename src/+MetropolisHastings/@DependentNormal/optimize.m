function results = optimize(this, theta, computeFitness)
  results = optimize@MetropolisHastings.Base(this, theta, computeFitness);
  results.scale = this.inference.proposal.scale;
end
