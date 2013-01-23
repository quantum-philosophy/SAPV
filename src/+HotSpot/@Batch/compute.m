function Data = compute(this, Pdyn, varargin)
  options = Options(varargin{:});

  leakage = options.leakage;
  U = options.parameters;
  stepIndex = options.get('stepIndex', []);

  Data = this.evaluate(Pdyn, stepIndex, leakage, U);
end
