function result = linear_programming(f, A, b, Aeq, beq, lb, ub, sense, options)
%LINEAR_PROGRAMMING  Solve a linear program with sensitivity output.
%   result = LINEAR_PROGRAMMING(f, A, b) solves min f'*x subject to
%   A*x <= b, x >= 0.
%
%   result = LINEAR_PROGRAMMING(f, A, b, Aeq, beq, lb, ub) adds
%   equality constraints and explicit bounds.
%
%   result = LINEAR_PROGRAMMING(f, A, b, Aeq, beq, lb, ub, sense)
%   specifies optimization direction: 'min' (default) or 'max'.
%
%   result = LINEAR_PROGRAMMING(..., options) passes custom
%   optimoptions to linprog (e.g. 'Algorithm', 'dual-simplex').
%
%   Inputs:
%       f       - n×1 objective coefficient vector
%       A       - m×n inequality constraint matrix
%       b       - m×1 inequality constraint RHS
%       Aeq     - p×n equality constraint matrix (default: [])
%       beq     - p×1 equality constraint RHS (default: [])
%       lb      - n×1 lower bound vector (default: [])
%       ub      - n×1 upper bound vector (default: [])
%       sense   - 'min' or 'max' (default: 'min')
%       options - optimoptions struct for linprog
%
%   Outputs:
%       result.x          - optimal solution (or [] if infeasible)
%       result.fval       - optimal objective value
%       result.exitflag   - linprog exit flag
%       result.output     - linprog output struct
%       result.lambda     - Lagrange multipliers (dual variables)
%           .lower        - shadow prices for lower bounds
%           .upper        - shadow prices for upper bounds
%           .ineqlin      - shadow prices for inequality constraints
%           .eqlin        - shadow prices for equality constraints
%       result.status     - 'optimal', 'infeasible', 'unbounded', or 'error'
%
%   Example:
%       f = [-5; -4; -6];  % max 5x1+4x2+6x3
%       A = [1 1 1; 3 2 4; 3 2 0];
%       b = [100; 210; 150];
%       lb = zeros(3,1);
%       r = linear_programming(f, A, b, [], [], lb, [], 'max');
%       fprintf('Optimal: fval=%.2f, dual(1)=%.2f\n', r.fval, r.lambda.ineqlin(1));
%
%   Notes:
%       - Shadow prices (lambda) indicate how much the objective would
%         improve per unit relaxation of the corresponding constraint.
%         This is OUTPUT sensitivity — for full parametric sensitivity
%         analysis, use the Optimization Toolbox's Sensitivity Analyzer.
%       - For large-scale problems, consider the 'dual-simplex' or
%         'interior-point' algorithms via optimoptions.
%
%   See also: integer_programming, genetic_algorithm, particle_swarm.

% ---------- 1. Default arguments ----------
if nargin < 4 || isempty(Aeq), Aeq = []; end
if nargin < 5 || isempty(beq), beq = []; end
if nargin < 6 || isempty(lb),  lb  = []; end
if nargin < 7 || isempty(ub),  ub  = []; end
if nargin < 8 || isempty(sense), sense = 'min'; end
if nargin < 9 || isempty(options)
    options = optimoptions('linprog', 'Display', 'off');
end

% ---------- 2. Validate dimensions ----------
f = f(:);
n = length(f);
if ~isempty(A) && size(A,2) ~= n
    error('linear_programming:DimensionMismatch', ...
        'A must have %d columns.', n);
end
if ~isempty(Aeq) && size(Aeq,2) ~= n
    error('linear_programming:DimensionMismatch', ...
        'Aeq must have %d columns.', n);
end

% ---------- 3. Solve ----------
try
    if strcmpi(sense, 'max')
        [x, fval, exitflag, output, lambda] = ...
            linprog(-f, A, b, Aeq, beq, lb, ub, options);
        fval = -fval;
    else
        [x, fval, exitflag, output, lambda] = ...
            linprog(f, A, b, Aeq, beq, lb, ub, options);
    end
catch ME
    error('linear_programming:LinprogFailed', ...
        'linprog failed: %s', ME.message);
end

% ---------- 4. Assemble output ----------
result.x        = x;
result.fval     = fval;
result.exitflag = exitflag;
result.output   = output;
result.lambda   = lambda;
result.sense    = sense;

% Interpret exit flag
switch exitflag
    case 1
        result.status = 'optimal';
    case {-2, -5}
        result.status = 'infeasible';
    case -3
        result.status = 'unbounded';
    otherwise
        result.status = 'error';
end

end
