function result = genetic_algorithm(objectiveFcn, bounds, options)
%GENETIC_ALGORITHM  Reusable GA wrapper with convergence tracking.
%   result = GENETIC_ALGORITHM(objectiveFcn, bounds) minimizes the given
%   objective function subject to variable bounds using MATLAB's ga.
%
%   result = GENETIC_ALGORITHM(objectiveFcn, bounds, options) passes
%   custom optimoptions to ga.
%
%   Inputs:
%       objectiveFcn - function handle f(x) returning scalar objective
%       bounds       - n×2 matrix [lower, upper] per variable
%       options      - optimoptions('ga', ...) struct (default: moderate defaults)
%
%   Outputs:
%       result.x           - best solution found
%       result.fval        - objective value at x
%       result.exitflag    - solver exit flag (1=converged, 0=maxIter, -1=stopped)
%       result.output      - full ga output struct
%       result.history     - struct with fields:
%           .fval          - best fval per generation
%           .meanFval      - mean fval per generation
%           .generations   - generation count
%       result.convergence - logical, whether convergence was achieved
%
%   Example:
%       % Minimize Rosenbrock function
%       fcn = @(x) (1-x(1))^2 + 100*(x(2)-x(1)^2)^2;
%       bnd = [-5 5; -5 5];
%       r = genetic_algorithm(fcn, bnd);
%       fprintf('Best: x=[%.4f %.4f], fval=%.6f\n', r.x, r.fval);
%
%   Notes:
%       - GA is a stochastic global optimizer. It does not guarantee
%         optimality. Always compare against a deterministic baseline
%         (LP, MILP, or DP) when possible.
%       - Run multiple seeds and report distribution, not just one best.
%       - For constrained problems, consider using a penalty function or
%         MATLAB's nonlinear constraint argument via optimoptions.
%
%   See also: particle_swarm, simulated_annealing, vns.

% ---------- 1. Validate inputs ----------
validateattributes(objectiveFcn, {'function_handle'}, {'scalar'}, ...
    mfilename, 'objectiveFcn', 1);
validateattributes(bounds, {'numeric'}, {'2d', 'ncols', 2, 'real'}, ...
    mfilename, 'bounds', 2);

nvars = size(bounds, 1);
lb = bounds(:, 1)';
ub = bounds(:, 2)';

% Check lb ≤ ub
if any(lb > ub)
    error('genetic_algorithm:InvalidBounds', ...
        'Lower bounds must not exceed upper bounds.');
end

% ---------- 2. Default options ----------
if nargin < 3 || isempty(options)
    options = optimoptions('ga', ...
        'Display', 'off', ...
        'PopulationSize', max(50, 10*nvars), ...
        'MaxGenerations', 100*nvars, ...
        'MaxStallGenerations', max(20, 5*nvars), ...
        'FunctionTolerance', 1e-6, ...
        'UseParallel', false);
end

% ---------- 3. Run GA with output function for history ----------
historyFval = [];
historyMean = [];

opts = options;
opts = optimoptions(opts, 'OutputFcn', @(opt, state, flag) ...
    gaOutputFcn(opt, state, flag));

    function stop = gaOutputFcn(~, state, ~)
        stop = false;
        if isfield(state, 'Best')
            historyFval(end+1) = state.Best(end);
        end
        if isfield(state, 'Population')
            popScores = state.Score;
            if ~isempty(popScores)
                historyMean(end+1) = mean(popScores);
            end
        end
    end

try
    [x, fval, exitflag, output] = ga(objectiveFcn, nvars, [], [], [], [], ...
        lb, ub, [], opts);
catch ME
    error('genetic_algorithm:GAFailed', ...
        'GA failed: %s', ME.message);
end

% ---------- 4. Assemble output ----------
result.x            = x;
result.fval         = fval;
result.exitflag     = exitflag;
result.output       = output;
result.history.fval = historyFval(:);
result.history.meanFval = historyMean(:);
result.history.generations = numel(historyFval);
result.convergence  = (exitflag == 1);

end
