function result = particle_swarm(objectiveFcn, bounds, options)
%PARTICLE_SWARM  Reusable PSO wrapper with convergence tracking.
%   result = PARTICLE_SWARM(objectiveFcn, bounds) minimizes the given
%   objective function subject to variable bounds using MATLAB's
%   particleswarm.
%
%   result = PARTICLE_SWARM(objectiveFcn, bounds, options) passes
%   custom optimoptions to particleswarm.
%
%   Inputs:
%       objectiveFcn - function handle f(x) returning scalar objective
%       bounds       - n×2 matrix [lower, upper] per variable
%       options      - optimoptions('particleswarm', ...) struct
%
%   Outputs:
%       result.x           - best solution found
%       result.fval        - objective value at x
%       result.exitflag    - solver exit flag (1=converged, 0=maxIter, -1=stopped)
%       result.output      - full particleswarm output struct
%       result.history     - struct with fields:
%           .fval          - best fval per iteration
%           .iterations    - iteration count
%       result.convergence - logical, whether convergence was achieved
%
%   Example:
%       % Minimize sphere function in 5 dimensions
%       fcn = @(x) sum(x.^2);
%       bnd = [-10 10; -10 10; -10 10; -10 10; -10 10];
%       r = particle_swarm(fcn, bnd);
%       fprintf('Best: fval=%.6f, iters=%d\n', r.fval, r.output.iterations);
%
%   Notes:
%       - PSO is a stochastic swarm intelligence optimizer. As with GA,
%         always run multiple seeds and report results distribution.
%       - For constrained problems, use a penalty function approach.
%       - PSO is generally faster than GA for continuous problems but
%         may converge prematurely on multimodal landscapes.
%
%   See also: genetic_algorithm, simulated_annealing, vns.

% ---------- 1. Validate inputs ----------
validateattributes(objectiveFcn, {'function_handle'}, {'scalar'}, ...
    mfilename, 'objectiveFcn', 1);
validateattributes(bounds, {'numeric'}, {'2d', 'ncols', 2, 'real'}, ...
    mfilename, 'bounds', 2);

nvars = size(bounds, 1);
lb = bounds(:, 1)';
ub = bounds(:, 2)';

if any(lb > ub)
    error('particle_swarm:InvalidBounds', ...
        'Lower bounds must not exceed upper bounds.');
end

% ---------- 2. Default options ----------
if nargin < 3 || isempty(options)
    options = optimoptions('particleswarm', ...
        'Display', 'off', ...
        'SwarmSize', max(30, min(100, 10*nvars)), ...
        'MaxIterations', 200*nvars, ...
        'MaxStallIterations', max(20, 5*nvars), ...
        'FunctionTolerance', 1e-6, ...
        'UseParallel', false);
end

% ---------- 3. Run PSO with output function for history ----------
historyFval = [];

opts = options;
opts = optimoptions(opts, 'OutputFcn', @(opt, state, ~) ...
    psoOutputFcn(opt, state));

    function stop = psoOutputFcn(~, state)
        stop = false;
        if isfield(state, 'Best')
            historyFval(end+1) = state.Best(end);
        end
    end

try
    [x, fval, exitflag, output] = particleswarm(objectiveFcn, nvars, ...
        lb, ub, opts);
catch ME
    error('particle_swarm:PSOFailed', ...
        'PSO failed: %s', ME.message);
end

% ---------- 4. Assemble output ----------
result.x            = x;
result.fval         = fval;
result.exitflag     = exitflag;
result.output       = output;
result.history.fval = historyFval(:);
result.history.iterations = numel(historyFval);
result.convergence  = (exitflag == 1);

end
