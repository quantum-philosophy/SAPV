function theta = propose(this, theta, proposal)
  theta = theta + proposal.coefficient * randn(length(theta), 1);
end
