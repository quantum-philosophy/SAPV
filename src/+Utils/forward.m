function model = forward(c, varargin)
  options = Options(varargin{:});

  switch lower(options.model)
  case 'observed'
    model = ForwardModel.(c.forward.method)( ...
      'floorplan', c.system.floorplan, ...
      'config',    c.temperature.configuration, ...
      'line',      c.temperature.line, ...
      'leakage',   c.leakage, ...
      'dieCount',  c.observations.dieCount, ...
      'timeIndex', c.observations.timeIndex, ...
      'Pdyn',      c.power.Pdyn);
  case 'complete'
    model = ForwardModel.(c.forward.method)( ...
      'floorplan', c.system.floorplan, ...
      'config',    c.temperature.configuration, ...
      'line',      c.temperature.line, ...
      'leakage',   c.leakage, ...
      'dieCount',  c.system.wafer.dieCount, ...
      'Pdyn',      c.power.Pdyn);
  otherwise
    assert(false);
  end
end
