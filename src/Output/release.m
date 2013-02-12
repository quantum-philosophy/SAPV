function release()
  global outputFile;
  global outputFolder;

  fclose(outputFile{end});
  outputFile(end) = [];
  outputFolder(end) = [];
end
