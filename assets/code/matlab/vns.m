function result = vns(objectiveFcn, x0, bounds, options)
%VNS  Variable Neighborhood Search for combinatorial and continuous optimization.
%   result = VNS(objectiveFcn, x0, bounds) performs variable neighborhood
%   search starting from x0 subject to variable bounds.
%
%   result = VNS(objectiveFcn, x0, bounds, options) passes custom options:
%       options.maxIter     - max iterations per neighborhood (default: 50)
%       options.maxTime     - max wall time in seconds (default: Inf)
%       options.kmax        - max neighborhood index (default: 3)
%       options.shakeSize   - base perturbation size (default: 0.1 * (ub-lb))
%       options.tolFun      - function tolerance for early stop (default: 1e-6)
%       options.verbose     - print progress if true (default: false)
%
%   Neighborhoods (automatically cycled 1..kmax):
%       k=1: Small perturbation (Gaussian around current best)
%       k=2: Medium perturbation (uniform sample in shrinking box)
%       k=3: Large perturbation (random restart within bounds)
%       For continuous problems, shakeSize controls perturbation magnitude.
%
%   Inputs:
%       objectiveFcn - function handle f(x) returning scalar objective
%       x0           - initial point (row vector)
%       bounds       - n×2 matrix [lower, upper] per variable
%       options      - struct with optional parameters (see above)
%
%   Outputs:
%       result.x           - best solution found
%       result.fval        - objective at best solution
%       result.history     - best fval per iteration
%       result.neighHist   - neighborhood index used at each iteration
%       result.nIter       - total iterations completed
%       result.elapsed_sec - wall time
%       result.converged   - logical, true if tolFun met
%
%   Notes:
%       - VNS systematically changes neighborhoods to escape local optima.
%         k=1 performs local search, k>1 diversifies the search.
%       - For pure combinatorial problems without continuous variables,
%         modify the perturb/improve functions for your representation.
%       - Always run multiple restarts and compare with GA/SA.
%
%   Example:
%       fcn = @(x) (x(1)^2 + x(2) - 11)^2 + (x(1) + x(2)^2 - 7)^2;
%       x0 = [0 0]; bnd = [-5 5; -5 5];
%       r = vns(fcn, x0, bnd);
%       fprintf('Best: [%.4f %.4f], fval=%.6f, iters=%d\n', r.x, r.fval, r.nIter);
%
%   Reference:
%       Mladenovic & Hansen (1997). Variable neighborhood search.
%
%   See also: genetic_algorithm, particle_swarm, simulated_annealing.

% ---------- 1. Parse options ----------
if nargin < 4, options = struct(); end
if ~isfield(options, 'maxIter'),   options.maxIter   = 50;   end
if ~isfield(options, 'maxTime'),   options.maxTime   = Inf;  end
if ~isfield(options, 'kmax'),      options.kmax      = 3;    end
if ~isfield(options, 'tolFun'),    options.tolFun    = 1e-6; end
if ~isfield(options, 'verbose'),   options.verbose   = false;end
if ~isfield(options, 'shakeSize')
    options.shakeSize = 0.1 * (bounds(:,2)' - bounds(:,1)');
end

% ---------- 2. Validate ----------
validateattributes(objectiveFcn, {'function_handle'}, {'scalar'}, mfilename, 'objectiveFcn', 1);
validateattributes(bounds, {'numeric'}, {'2d', 'ncols', 2}, mfilename, 'bounds', 3);
nvars = numel(x0); lb = bounds(:,1)'; ub = bounds(:,2)';

% ---------- 3. Initialize ----------
x = x0(:)';
fx = objectiveFcn(x);
xBest = x; fBest = fx;
history = fx; neighHist = []; iter = 0;
tStart = tic;

% ---------- 4. Main VNS loop ----------
while iter < options.maxIter && toc(tStart) < options.maxTime
    k = 1;
    while k <= options.kmax && iter < options.maxIter
        iter = iter + 1;
        
        % Shake: generate x' in neighborhood N_k(x)
        xp = shake(x, lb, ub, k, nvars, options);
        xp = max(min(xp, ub), lb);  % project to bounds
        
        % Improve: local search from xp
        [xpp, fxpp] = localSearch(objectiveFcn, xp, lb, ub, options);
        
        % Move or not
        if fxpp < fBest - options.tolFun
            x = xpp; fx = fxpp;
            xBest = xpp; fBest = fxpp;
            k = 1;  % reset to first neighborhood
        else
            k = k + 1;  % next neighborhood
        end
        
        history(end+1) = fBest; %#ok<AGROW>
        neighHist(end+1) = k; %#ok<AGROW>
        
        if options.verbose && mod(iter, 10) == 0
            fprintf('Iter %d: fval=%.6f, k=%d\n', iter, fBest, k);
        end
    end
end

% ---------- 5. Assemble output ----------
result.x          = xBest;
result.fval       = fBest;
result.history    = history;
result.neighHist  = neighHist;
result.nIter      = iter;
result.elapsed_sec = toc(tStart);
result.converged  = iter < options.maxIter;

end

% ========== Helper functions ==========

function xp = shake(x, lb, ub, k, nvars, options)
    ss = options.shakeSize;
    sigma = ss * (0.5 ^ (k-1));  % decreasing radius per k
    if k == 3
        % Random restart within bounds
        xp = lb + rand(1, nvars) .* (ub - lb);
    else
        xp = x + sigma .* randn(1, nvars);
    end
end

function [xBest, fBest] = localSearch(fcn, x0, lb, ub, options)
    % Simple coordinate descent as improve step
    x = x0(:)';
    fx = fcn(x);
    improved = true;
    n = numel(x);
    maxLocalIter = 20;
    
    for i = 1:maxLocalIter
        if ~improved, break; end
        improved = false;
        for j = 1:n
            step = options.shakeSize(j) * 0.5;
            for sgn = [-1, 1]
                xc = x; xc(j) = xc(j) + sgn * step;
                xc(j) = max(min(xc(j), ub(j)), lb(j));
                fxc = fcn(xc);
                if fxc < fx - options.tolFun
                    x = xc; fx = fxc;
                    improved = true;
                end
            end
        end
    end
    xBest = x; fBest = fx;
end
