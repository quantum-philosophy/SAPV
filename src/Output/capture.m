function capture(path, name)
  if nargin < 1, path = []; end
  if nargin < 2, name = []; end

  global outputFolder;
  global outputFile;

  if isempty(path)
    outputFolder = { Utils.makeTimeStamp };
    outputFile = {};
  else
    outputFolder{end + 1} = path;
  end

  if ~isempty(name)
    outputFolder{end} = [ outputFolder{end}, ' ', name ];
  end

  folder = File.join(outputFolder{:});
  mkdir(folder);
  outputFile{end + 1} = fopen(File.join(folder, 'Report.txt'), 'w');
end
