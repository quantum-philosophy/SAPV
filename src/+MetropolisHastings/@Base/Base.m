classdef Base < handle
  properties (SetAccess = 'private')
    verbose
    mapping
    inference
    qmeasT
    model
  end

  methods
    function this = Base(c, m, model)
      this.verbose = c.verbose;
      this.mapping = c.process.constrainMapping(c.observations.dieIndex);
      this.inference = c.inference;
      this.qmeasT = transpose(m.Tmeas(:));
      this.model = model;
    end
  end

  methods (Access = 'protected')
    proposal = optimize(this, theta, computeFitness)
  end

  methods (Abstract, Access = 'protected')
    theta = propose(this, theta, proposal)
  end
end
