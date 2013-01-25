function fixRNG
  if File.exist('rng.mat')
    load('rng.mat');
  else
    r = rng;
    save('rng.mat', 'r', '-v7.3');
  end

  rng(r);
end
