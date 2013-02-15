function theta = propose(this, theta, proposal)
  %
  % Reference:
  %
  % Multivariate Student's t distribution,
  % http://www.statlect.com/mcdstu1.htm.
  %
  z = trnd(proposal.df, length(theta), 1);
  theta = proposal.theta + proposal.scale * proposal.coefficient * z;
end
