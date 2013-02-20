function string = stamp(c, name, varargin)
  hash = DataHash(Utils.toString(varargin));
  string = sprintf('Cache/%03d_%s_%s', ...
    c.system.processorCount, name, hash);
end
