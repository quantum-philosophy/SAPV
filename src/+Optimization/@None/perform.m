function [ theta, covariance, coefficient ] = perform(this, theta, ~, varargin)
  covariance = eye(length(theta));
  coefficient = covariance;
end
