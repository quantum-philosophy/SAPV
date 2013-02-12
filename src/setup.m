function setup
  warning('off', 'MATLAB:dispatcher:nameConflict');
  addpath('Output');

  use('LinearAlgebra');
  use('DataAnalysis');
  use('TemperatureAnalysis');
  use('SystemSimulation');
  use('Approximation');
  use('StatisticalInference');
  use('ProbabilityTheory');
  use('Vendor', 'DataHash');
end
