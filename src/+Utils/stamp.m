function string = stamp(c, name, varargin)
  hash = DataHash({ c.toString, varargin });

  match = regexp(name, '^(.)+\.([^.])+$', 'tokens');
  if ~isempty(match)
    name = match{1}{1};
    extension = match{1}{2};
  else
    extension = [];
  end

  string = sprintf('%03d_%s_%s', ...
    c.system.processorCount, name, hash);

  if ~isempty(extension)
    string = [ string, '.', extension ];
  end
end
