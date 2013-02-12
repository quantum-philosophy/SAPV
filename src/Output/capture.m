function capture(path)
  if nargin == 0, path = []; end

  global outputFolder;
  global outputFile;

  if isempty(path)
    outputFolder = { Utils.makeTimeStamp };
    outputFile = {};
  else
    outputFolder{end + 1} = path;
  end

  folder = File.join(outputFolder{:});
  mkdir(folder);
  outputFile{end + 1} = fopen(File.join(folder, 'Report.txt'), 'w');
end
