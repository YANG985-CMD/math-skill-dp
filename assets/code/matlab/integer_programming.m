function result = integer_programming(f, intcon, A, b, Aeq, beq, lb, ub, sense, options)
%INTEGER_PROGRAMMING  Solve a mixed-integer linear program.
%   result = INTEGER_PROGRAMMING(f, intcon) solves min f'*x with
%   variables indexed by intcon constrained to be integer.
%
%   result = INTEGER_PROGRAMMING(f, intcon, A, b, Aeq, beq, lb, ub)
%   adds constraints and bounds.
%
%   result = INTEGER_PROGRAMMING(..., sense) specifies 'min' or 'max'.
%
%   result = INTEGER_PROGRAMMING(..., options) passes optimoptions.
%
%   Inputs:
%       f       - n×1 objective coefficient vector
%       intcon  - vector of indices that must be integer
%       A, b    - inequality constraints A*x <= b
%       Aeq,beq - equality constraints Aeq*x == beq
%       lb, ub  - variable bounds
%       sense   - 'min' (default) or 'max'
%       options - optimoptions for intlinprog
%
%   Outputs:
%       result.x          - optimal solution (integer at intcon indices)
%       result.fval       - optimal objective value
%       result.exitflag   - intlinprog exit flag
%       result.output     - intlinprog output struct
%       result.gap        - struct with fields:
%           .absolute     - |best Integer - best Bound| at termination
%           .relative     - relative MIP gap
%       result.status     - 'optimal', 'feasible', 'infeasible', or 'error'
%
%   Example:
%       f = [8; 1];                   % min 8*x1 + x2
%       intcon = 2;                   % x2 must be integer
%       A = [1 2; -4 -1; 2 1];
%       b = [-14; -33; 20];
%       lb = [0; 0];
%       r = integer_programming(f, intcon, A, b, [], [], lb);
%       fprintf('MIP gap: %.2f%%\n', r.gap.relative);
%
%   Notes:
%       - intlinprog uses branch-and-bound. For large problems, set a
%         time limit or relative gap tolerance via optimoptions.
%       - Always check the MIP gap. exitflag=2 means feasible but not
%         proven optimal — the gap tells you how far from optimality
%         you might be.
%       - 0-1 variables can be modeled using lb=0, ub=1 + intcon index.
%
%   See also: linear_programming, genetic_algorithm.

% ---------- 1. Default arguments ----------
if nargin < 3 || isempty(A),   A   = []; end
if nargin < 4 || isempty(b),   b   = []; end
if nargin < 5 || isempty(Aeq), Aeq = []; end
if nargin < 6 || isempty(beq), beq = []; end
if nargin < 7 || isempty(lb),  lb  = []; end
if nargin < 8 || isempty(ub),  ub  = []; end
if nargin < 9 || isempty(sense), sense = 'min'; end
if nargin < 10 || isempty(options)
    options = optimoptions('intlinprog', 'Display', 'off');
end

% ---------- 2. Validate ----------
f = f(:);
n = length(f);
validateattributes(intcon, {'numeric'}, {'vector', 'integer', 'positive', '<=', n}, ...
    mfilename, 'intcon', 2);

if ~isempty(A) && size(A,2) ~= n
    error('integer_programming:DimensionMismatch', ...
        'A must have %d columns.', n);
end
if ~isempty(Aeq) && size(Aeq,2) ~= n
    error('integer_programming:DimensionMismatch', ...
        'Aeq must have %d columns.', n);
end

% ---------- 3. Solve ----------
try
    if strcmpi(sense, 'max')
        [x, fval, exitflag, output] = ...
            intlinprog(-f, intcon, A, b, Aeq, beq, lb, ub, options);
        fval = -fval;
    else
        [x, fval, exitflag, output] = ...
            intlinprog(f, intcon, A, b, Aeq, beq, lb, ub, options);
    end
catch ME
    error('integer_programming:IntlinprogFailed', ...
        'intlinprog failed: %s', ME.message);
end

% ---------- 4. Compute MIP gap ----------
gapAbs = NaN;
gapRel = NaN;
if exitflag == 1 || exitflag == 2
    % bestBound is available from output
    if isfield(output, 'bounds') && ~isempty(output.bounds)
        bestBound = output.bounds(end);
        gapAbs = abs(fval - bestBound);
        gapRel = 100 * gapAbs / max(1, abs(fval));
    end
end

% ---------- 5. Assemble output ----------
result.x        = x;
result.fval     = fval;
result.exitflag = exitflag;
result.output   = output;
result.gap.absolute = gapAbs;
result.gap.relative = gapRel;
result.sense    = sense;

% Interpret exit flag
switch exitflag
    case 1
        result.status = 'optimal';       % proven optimal
    case 2
        result.status = 'feasible';      % feasible but not proven optimal
    case {-2, -5}
        result.status = 'infeasible';
    otherwise
        result.status = 'error';
end

end
