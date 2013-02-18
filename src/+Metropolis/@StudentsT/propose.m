function theta = propose(this, theta, proposal)
  %
  % Reference:
  %
  % Multivariate Student's t distribution,
  % http://www.statlect.com/mcdstu1.htm.
  %
  z = trnd(proposal.degreesOfFreedom, length(theta), 1);
  theta = proposal.theta + proposal.scale * proposal.coefficient * z;

  %
  % Reference:
  %
  % Multivariate t-distribution,
  % http://en.wikipedia.org/wiki/Multivariate_t-distribution.
  %
  % z = randn(length(theta), 1);
  % x = chi2rnd(proposal.degreesOfFreedom);
  % theta = proposal.theta + ...
  %   proposal.scale * proposal.coefficient * z * ...
  %   sqrt(proposal.degreesOfFreedom / x);
end
