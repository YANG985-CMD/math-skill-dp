function result = simulated_annealing(objectiveFcn, x0, bounds, options)
%SIMULATED_ANNEALING  Simulated Annealing for global optimization.
%   result = SIMULATED_ANNEALING(objectiveFcn, x0, bounds) minimizes
%   objectiveFcn starting from x0 subject to bounds.
%
%   result = SIMULATED_ANNEALING(objectiveFcn, x0, bounds, options)
%   passes custom optimoptions('simulannealbnd', ...).
%
%   Inputs:
%       objectiveFcn - function handle f(x) returning scalar objective
%       x0           - 1×n initial point
%       bounds       - n×2 matrix [lower, upper] per variable
%       options      - optimoptions struct (default: fast annealing schedule)
%
%   Outputs:
%       result.x           - best solution found
%       result.fval        - objective value at x
%       result.exitflag    - exit flag (1=converged, 0=maxIter, -1=stopped)
%       result.output      - full simulannealbnd output
%       result.history     - struct with fields: .fval, .temperature
%       result.convergence - logical, whether convergence reached
%
%   Algorithm Parameters (via optimoptions):
%       - InitialTemperature: starting temperature (default: 100)
%       - TemperatureFcn: cooling schedule (default: 'temperatureexp')
%       - MaxIterations: max iterations (default: Inf → auto)
%       - ReannealInterval: reannealing interval
%
%   Notes:
%       - SA probabilistically accepts worse solutions to escape local
%         optima, controlled by the temperature schedule.
%       - Best for problems with many local optima where gradient methods
%         fail. For simple convex problems, use LP or fmincon instead.
%       - Always compare multiple SA runs with different seeds.
%
%   Example:
%       fcn = @(x) (x(1)^2 + x(2) - 11)^2 + (x(1) + x(2)^2 - 7)^2;
%       x0 = [0 0]; bnd = [-5 5; -5 5];
%       r = simulated_annealing(fcn, x0, bnd);
%       fprintf('Best: [%.4f %.4f], fval=%.6f\n', r.x, r.fval);
%
%   See also: genetic_algorithm, particle_swarm, vns.

% ---------- 1. Validate inputs ----------
validateattributes(objectiveFcn, {'function_handle'}, {'scalar'}, ...
    mfilename, 'objectiveFcn', 1);
validateattributes(x0, {'numeric'}, {'vector', 'real', 'finite'}, ...
    mfilename, 'x0', 2);
validateattributes(bounds, {'numeric'}, {'2d', 'ncols', 2, 'real'}, ...
    mfilename, 'bounds', 3);

nvars = numel(x0);
if size(bounds,1) ~= nvars
    error('simulated_annealing:DimensionMismatch', ...
        'bounds must have %d rows.', nvars);
end
lb = bounds(:, 1)';
ub = bounds(:, 2)';
if any(lb > ub)
    error('simulated_annealing:InvalidBounds', ...
        'Lower bounds must not exceed upper bounds.');
end

% ---------- 2. Default options ----------
if nargin < 4 || isempty(options)
    options = optimoptions('simulannealbnd', ...
        'Display', 'off', ...
        'InitialTemperature', 100, ...
        'MaxIterations', 500 * nvars, ...
        'MaxFunctionEvaluations', 3000 * nvars, ...
        'FunctionTolerance', 1e-6);
end

% ---------- 3. Problem structure ----------
problem = struct();
problem.objective = objectiveFcn;
problem.x0 = x0(:)';
problem.lb = lb;
problem.ub = ub;
problem.options = options;
problem.solver = 'simulannealbnd';

% ---------- 4. Run with output function ----------
historyFval = [];
historyTemp  = [];

opts = options;
opts = optimoptions(opts, 'OutputFcn', @saOutputFcn);

    function stop = saOutputFcn(~, optimValues, ~)
        stop = false;
        if isfield(optimValues, 'bestfval')
            historyFval(end+1) = optimValues.bestfval;
        end
        if isfield(optimValues, 'temperature')
            historyTemp(end+1) = optimValues.temperature;
        end
    end

try
    [x, fval, exitflag, output] = simulannealbnd(problem.objective, ...
        problem.x0, problem.lb, problem.ub, opts);
catch ME
    error('simulated_annealing:SAFailed', 'SA failed: %s', ME.message);
end

% ---------- 5. Assemble output ----------
result.x            = x;
result.fval         = fval;
result.exitflag     = exitflag;
result.output       = output;
result.history.fval = historyFval(:);
result.history.temperature = historyTemp(:);
result.convergence  = (exitflag == 1);

end
