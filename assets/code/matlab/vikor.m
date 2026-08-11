function result = vikor(data, weights, benefitMask, v)
%VIKOR  VIseKriterijumska Optimizacija I Kompromisno Resenje.
%   result = VIKOR(data) performs multi-criteria ranking with default
%   equal weights and benefit-direction defaults.
%
%   result = VIKOR(data, weights, benefitMask, v) specifies custom
%   weights, indicator direction, and the group-utility weight v.
%
%   Inputs:
%       data        - m×n matrix, m alternatives × n criteria
%       weights     - 1×n weight vector (default: equal)
%       benefitMask - 1×n logical, true=benefit, false=cost (default: all true)
%       v           - weight of group utility, 0≤v≤1 (default: 0.5)
%                     v>0.5 → majority preference
%                     v=0.5 → consensus
%                     v<0.5 → veto emphasis
%
%   Outputs:
%       result.S        - m×1 group utility (weighted Manhattan distance)
%       result.R        - m×1 individual regret (weighted Chebyshev distance)
%       result.Q        - m×1 VIKOR index (compromise measure)
%       result.ranking  - m×1 ranking based on Q (1=best, smallest Q)
%       result.compromise - struct with accepted solutions and conditions
%
%   VIKOR Acceptance Conditions:
%       1. Acceptable Advantage: Q(a'')-Q(a') >= DQ (=1/(m-1))
%       2. Acceptable Stability: a' must also be best by S or R
%       If both conditions pass → a' is the compromise solution.
%       If only condition 2 passes → a', a'', ... are compromise set.
%
%   Example:
%       A = [4 7 10; 5 8 9; 6 9 8];     % 3 alternatives, 3 criteria
%       w = [0.3 0.4 0.3];
%       bm = [true true false];          % first two benefit, third cost
%       r = vikor(A, w, bm, 0.5);
%       fprintf('Q scores: %.4f\n', r.Q);
%       disp(r.compromise);
%
%   Reference:
%       Opricovic & Tzeng (2004). Compromise solution by MCDM methods.
%
%   See also: topsis, entropy_weight, critic_weight.

% ---------- 1. Input validation ----------
validateattributes(data, {'numeric'}, {'2d','nonempty','real','finite'}, ...
    mfilename, 'data', 1);
[m, n] = size(data);
if m < 2
    error('vikor:NotEnoughAlternatives', 'At least 2 alternatives required.');
end

if nargin < 2 || isempty(weights),     weights     = ones(1, n); end
if nargin < 3 || isempty(benefitMask), benefitMask = true(1, n); end
if nargin < 4 || isempty(v),           v           = 0.5;        end

validateattributes(weights, {'numeric'}, {'vector','numel',n,'nonnegative'}, ...
    mfilename, 'weights', 2);
validateattributes(benefitMask, {'logical'}, {'vector','numel',n}, ...
    mfilename, 'benefitMask', 3);
validateattributes(v, {'numeric'}, {'scalar','>=',0,'<=',1}, ...
    mfilename, 'v', 4);

weights = weights(:)' ./ sum(weights);

% ---------- 2. Determine ideal/anti-ideal per criterion ----------
best  = zeros(1, n);
worst = zeros(1, n);
for j = 1:n
    col = data(:, j);
    if benefitMask(j)
        best(j)  = max(col);
        worst(j) = min(col);
    else
        best(j)  = min(col);
        worst(j) = max(col);
    end
end

% ---------- 3. Normalized Manhattan (S) and Chebyshev (R) distances ----------
S = zeros(m, 1);
R = zeros(m, 1);
for i = 1:m
    diffB = best - data(i, :);
    diffW = worst - data(i, :);
    % Avoid division by zero
    safeDen = max(abs(diffW), 1e-12);
    ratios = abs(diffB) ./ safeDen;
    S(i) = sum(weights .* ratios);
    R(i) = max(weights .* ratios);
end

% ---------- 4. Compute VIKOR index Q ----------
Smin = min(S); Smax = max(S);
Rmin = min(R); Rmax = max(R);

if Smax == Smin, Srange = 1; else, Srange = Smax - Smin; end
if Rmax == Rmin, Rrange = 1; else, Rrange = Rmax - Rmin; end

Q = v * (S - Smin) ./ Srange + (1 - v) * (R - Rmin) ./ Rrange;

% ---------- 5. Ranking by Q (ascending: smaller Q is better) ----------
[Qsorted, sortIdx] = sort(Q);
[~, ranking] = sort(sortIdx);  % rank 1 = best

% ---------- 6. Check acceptance conditions ----------
DQ = 1 / (m - 1);
a1_idx = sortIdx(1);
a2_idx = sortIdx(2);

cond1 = (Q(a2_idx) - Q(a1_idx)) >= DQ;  % Acceptable Advantage
cond2a = S(a1_idx) <= S(a2_idx);          % Stability by S
cond2b = R(a1_idx) <= R(a2_idx);          % Stability by R

accepted = {};
if cond1 && (cond2a || cond2b)
    accepted{end+1} = a1_idx;
elseif ~cond1 && cond2a && cond2b
    accepted{end+1} = a1_idx;
elseif cond2a || cond2b
    % Compromise set: all with Q-Qsorted(1) < DQ
    cutoff = Qsorted(1) + DQ;
    accepted_idx = find(Q <= cutoff);
    accepted = num2cell(accepted_idx(:)');
end

% ---------- 7. Assemble output ----------
result.S          = S;
result.R          = R;
result.Q          = Q;
result.ranking    = ranking;
result.v          = v;
result.compromise.accepted  = accepted;
result.compromise.cond1     = cond1;
result.compromise.cond2a    = cond2a;
result.compromise.cond2b    = cond2b;
result.compromise.DQ        = DQ;

end
