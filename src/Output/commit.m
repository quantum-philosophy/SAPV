function commit(name, varargin)
  global outputFolder;
  if isempty(outputFolder), return; end
  Plot.save(File.join(outputFolder{:}, name), varargin{:});
end
