function [ fh, xh, gh, H, stepCount, functionCount, retcodeh ] = csminwel(fcn, x0, H0, grad, varargin)
  %
  % Minimization using the quasi-Newton method with BFGS updates.
  %
  % "The programs are somewhat more robust, apparently, than the stock Matlab programs
  % that do about the same thing. The minimizer can negotiate discontinuous 'cliffs'
  % without getting stuck."
  %
  % Author: Chris Sims
  % URL: http://sims.princeton.edu/yftp/optimize/
  %

  options = Options(varargin{:});

  verbose = options.get('verbose', false);
  threshold = options.get('stallThreshold', 1e-7);
  maximalStepCount = options.get('maximalStepCount', 1e4);

  if verbose
    printf = @(varargin) fprintf(varargin{:});
  else
    printf = @(varargin) [];
  end

  done = false;
  stepCount = 0;
  functionCount = 0;
  useNumericalGradient = isempty(grad);
  parameterCount = max(size(x0));

  f0 = feval(fcn, x0);
  functionCount = functionCount + 1;

  if f0 > 1e50, error('Bad initial parameters.'); end

  if useNumericalGradient
    if length(grad) == 0
      [ g badg ] = numgrad(fcn, x0);
    else
      badg = any(find(grad == 0));
      g = grad;
    end
  else
    [ g badg ] = feval(grad, x0);
  end

  retcode3 = 101;
  x = x0;
  f = f0;
  H = H0;

  while ~done
    stepCount = stepCount + 1;
    g1 = []; g2 = []; g3 = [];
    [ f1 x1 fc retcode1 ] = csminit(fcn, x, f, g, badg, H);
    functionCount = functionCount + fc;

    printf('%10d: evaluations %10d, objective %10.4f.\n', stepCount, functionCount, f);

    if retcode1 ~= 1
      if retcode1 == 2 | retcode1 == 4
        wall1=1; badg1=1;
      else
        if useNumericalGradient
          [ g1 badg1 ] = numgrad(fcn, x1);
        else
          [ g1 badg1 ] = feval(grad, x1);
        end
        wall1 = badg1;
      end

      if wall1 & (length(H) > 1)
        printf('Cliff. Perturbing search direction.\n');

        Hcliff = H + diag(diag(H) .* rand(parameterCount, 1));

        [ f2 x2 fc retcode2 ] = csminit(fcn, x, f, g, badg, Hcliff);
        functionCount = functionCount + fc;

        if f2 < f
          if retcode2 == 2 | retcode2 == 4
            wall2 = 1; badg2 = 1;
          else
            if useNumericalGradient
              [ g2 badg2 ] = numgrad(fcn, x2);
            else
              [ g2 badg2 ] = feval(grad, x2);
            end
            wall2 = badg2;
          end

          if wall2
            printf('Cliff again. Try traversing.\n')

            if norm(x2-x1) < 1e-13
              f3 = f; x3 = x; badg3 = 1; retcode3 = 101;
            else
              gcliff = ((f2 - f1) / ((norm(x2 - x1))^2)) * (x2 - x1);
              if size(x0, 2) > 1, gcliff = gcliff'; end
              [ f3 x3 fc retcode3 ] = csminit(fcn, x, f, gcliff, 0, eye(parameterCount));
              functionCount = functionCount + fc;
              if retcode3 == 2 | retcode3 == 4
                wall3 = 1; badg3 = 1;
              else
                if useNumericalGradient
                  [ g3 badg3 ] = numgrad(fcn, x3);
                else
                  [ g3 badg3 ] = feval(grad, x3);
                end
                wall3 = badg3;
              end
            end
          else
            f3 = f; x3 = x; badg3 = 1; retcode3 = 101;
          end
        else
          f3 = f; x3 = x; badg3 = 1; retcode3 = 101;
        end
      else
        f2 = f; f3 = f; badg2 = 1; badg3 = 1; retcode2 = 101; retcode3 = 101;
      end
    else
       f2 = f; f3 = f; f1 = f; retcode2 = retcode1; retcode3 = retcode1;
    end

    if f3 < f - threshold & badg3 == 0
      ih = 3;
      fh = f3; xh = x3; gh = g3; badgh = badg3; retcodeh = retcode3;
    elseif f2 < f - threshold & badg2 == 0
      ih = 2;
      fh = f2; xh = x2; gh = g2; badgh = badg2; retcodeh = retcode2;
    elseif f1 < f - threshold & badg1 == 0
      ih = 1;
      fh = f1; xh = x1; gh = g1; badgh = badg1; retcodeh = retcode1;
    else
      [ fh, ih ] = min([ f1, f2, f3 ]);
      switch ih
      case 1
        xh = x1;
      case 2
        xh = x2;
      case 3
        xh = x3;
      end
      retcodei = [ retcode1, retcode2, retcode3 ];
      retcodeh = retcodei(ih);
      if exist('gh')
        nogh = isempty(gh);
      else
        nogh = 1;
      end
      if nogh
        if useNumericalGradient
          [ gh badgh ] = numgrad(fcn, xh);
        else
          [ gh badgh ] = feval(grad, xh);
        end
      end
      badgh = 1;
    end

    stuck = abs(fh - f) < threshold;
    if (~badg) & (~badgh) & (~stuck)
      H = bfgsi(H, gh - g, xh - x);
    end

    if stepCount > maximalStepCount
      printf('The limit on the number of iterations has been reached.\n');
      done = true;
    elseif stuck
      printf('The improvement of the objective function has dropped below %e.\n', threshold);
      done = true;
    end

    if verbose
      rc = retcodeh;
      if rc == 1
        printf('Zero gradient.\n');
      elseif rc == 6
        printf('Smallest step still improving too slow, reversed gradient.\n');
      elseif rc == 5
        printf('Largest step still improving too fast.\n');
      elseif (rc == 4) | (rc == 2)
        printf('Back and forth on step length never finished.\n');
      elseif rc == 3
        printf('Smallest step still improving too slow.\n');
      elseif rc == 7
        printf('Warning: possible inaccuracy in H matrix.\n');
      end
    end

    f = fh;
    x = xh;
    g = gh;
    badg = badgh;
  end
end

function [ g, badg ] = numgrad(fcn, x)
  delta = 1e-6;
  n = length(x);
  tvec = delta * eye(n);
  g = zeros(n, 1);
  f0 = feval(fcn, x);
  badg = 0;
  for i = 1:n
    scale = 1;
    if size(x, 1) > size(x, 2)
      tvecv = tvec(i, :);
    else
      tvecv = tvec(:, i);
    end
    g0 = (feval(fcn, x + scale * tvecv') - f0) / (scale * delta);
    if abs(g0) < 1e15
      g(i) = g0;
    else
      g(i) = 0;
      badg = 1;
    end
  end
end

function H = bfgsi(H0, dg, dx)
  if size(dg,2) > 1, dg = dg'; end
  if size(dx, 2) > 1, dx = dx'; end
  Hdg = H0 * dg;
  dgdx = dg' * dx;
  if abs(dgdx) > 1e-12
    H = H0 + (1 + (dg' * Hdg) / dgdx) * (dx * dx') / ...
      dgdx - (dx * Hdg' + Hdg * dx') / dgdx;
  else
    warning('bfgs update failed.');
    H = H0;
  end
end

function [ fhat, xhat, functionCount, retcode ] = csminit(fcn, x0, f0, g0, badg, H0)
  ANGLE = .005;
  THETA = .3;
  FCHANGE = 1000;
  MINLAMB = 1e-9;
  MINDFAC = .01;
  functionCount = 0;
  lambda = 1;
  xhat = x0;
  f = f0;
  fhat = f0;
  g = g0;
  gnorm = norm(g);

  if (gnorm < 1.e-12) & ~badg
    retcode = 1;
    dxnorm = 0;
    return;
  end

  dx = -H0 * g;
  dxnorm = norm(dx);

  if dxnorm > 1e12
    warning('Near-singular H problem.')
    dx = dx * FCHANGE / dxnorm;
  end

  dfhat = dx' * g0;

  if ~badg
    a = -dfhat / (gnorm * dxnorm);
    if a < ANGLE
      dx = dx - (ANGLE * dxnorm / gnorm + dfhat / (gnorm * gnorm)) * g;
      dx = dx * dxnorm / norm(dx);
      dfhat = dx' * g;
    end
  end

  done = false;
  factor = 3;
  shrink = 1;
  lambdaMin = 0;
  lambdaMax = Inf;
  lambdaPeak = 0;
  fPeak = f0;
  lambdahat = 0;

  while ~done
    if size(x0, 2)>1
      dxtest = x0 + dx' * lambda;
    else
      dxtest = x0 + dx * lambda;
    end

    f = feval(fcn, dxtest);
    functionCount = functionCount + 1;

    if f < fhat
      fhat = f;
      xhat = dxtest;
      lambdahat = lambda;
    end

    shrinkSignal = (~badg & (f0 - f < max([ -THETA * dfhat * lambda 0]))) | (badg & (f0 - f) < 0);
    growSignal = ~badg & ((lambda > 0) & (f0 - f > -(1 - THETA) * dfhat * lambda));

    if shrinkSignal & ((lambda > lambdaPeak) | (lambda < 0))
      if (lambda > 0) & ((~shrink) | (lambda / factor <= lambdaPeak))
        shrink = 1;
        factor = factor^.6;
        while lambda / factor <= lambdaPeak
          factor = factor^.6;
        end
        if abs(factor - 1) < MINDFAC
          if abs(lambda) < 4
            retcode = 2;
          else
            retcode = 7;
          end
          done = true;
        end
      end

      if (lambda < lambdaMax) & (lambda > lambdaPeak)
        lambdaMax = lambda;
      end

      lambda = lambda / factor;
      if abs(lambda) < MINLAMB
        if (lambda > 0) & (f0 <= fhat)
          lambda = -lambda * factor^6;
        else
          if lambda < 0
            retcode = 6;
          else
            retcode = 3;
          end
          done = true;
        end
      end
    elseif (growSignal & lambda > 0) | (shrinkSignal & ((lambda <= lambdaPeak) & (lambda > 0)))
      if shrink
        shrink = 0;
        factor = factor^.6;
        if abs(factor - 1) < MINDFAC
          if abs(lambda) < 4
            retcode = 4;
          else
            retcode = 7;
          end
          done = true;
        end
      end

      if (f < fPeak) & (lambda > 0)
        fPeak = f;
        lambdaPeak = lambda;
        if lambdaMax <= lambdaPeak
          lambdaMax = lambdaPeak * factor * factor;
        end
      end

      lambda = lambda * factor;
      if abs(lambda) > 1e20
        retcode = 5;
        done = true;
      end
    else
      done = true;
      if factor < 1.2
        retcode = 7;
      else
        retcode = 0;
      end
    end
  end
end
