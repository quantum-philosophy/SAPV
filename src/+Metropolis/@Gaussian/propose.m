function theta = propose(this, theta, proposal)
  z = randn(length(theta), 1);
  theta = theta + proposal.scale * proposal.coefficient * z;
end
