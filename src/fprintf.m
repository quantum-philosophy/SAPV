function fprintf(varargin)
  %
  % If something wants to write to a specific file, let it do it.
  %
  if ~ischar(varargin{1})
    builtin('fprintf', varargin{:});
    return;
  end

  global outputFile;

  if isempty(outputFile)
    builtin('fprintf', 1, varargin{:});
  else
    %
    % Duplicate the output.
    %
    builtin('fprintf', 1, varargin{:});
    builtin('fprintf', outputFile{end}, varargin{:});
  end
end
