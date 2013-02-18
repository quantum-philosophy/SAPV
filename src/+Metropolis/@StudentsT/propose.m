function theta = propose(this, ~, proposal, count)
  %
  % Reference:
  %
  % Multivariate Student's t distribution,
  % http://www.statlect.com/mcdstu1.htm.
  %

  if ~exist('count', 'var')
    z = trnd(proposal.degreesOfFreedom, length(proposal.theta), 1);
    theta = proposal.theta + proposal.scale * proposal.coefficient * z;
  else
    z = trnd(proposal.degreesOfFreedom, length(proposal.theta), count);
    theta = repmat(proposal.theta, 1, count) + ...
      proposal.scale * proposal.coefficient * z;
  end
end
