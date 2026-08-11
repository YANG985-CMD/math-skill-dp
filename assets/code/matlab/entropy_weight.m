function result = entropy_weight(data, benefitMask, normMethod)
%ENTROPY_WEIGHT  Compute objective weights via information entropy.
%   result = ENTROPY_WEIGHT(data) returns entropy-derived weights and
%   weighted scores for the decision matrix.
%
%   result = ENTROPY_WEIGHT(data, benefitMask) sets indicator direction.
%
%   result = ENTROPY_WEIGHT(data, benefitMask, normMethod) selects
%   normalization. Options:
%       'minmax'    – min-max normalization (default)
%       'zscore'    – z-score standardization
%       'proportion' – proportion normalization
%
%   Inputs:
%       data        - m×n matrix of m alternatives × n indicators
%       benefitMask - 1×n logical, true=benefit, false=cost (default: all true)
%       normMethod  - char, normalization strategy (default: 'minmax')
%
%   Outputs:
%       result.weights      - 1×n entropy-derived weight vector
%       result.scores       - m×1 weighted composite scores
%       result.normalized   - m×n normalized matrix
%       result.entropy      - 1×n information entropy per indicator
%       result.divergence   - 1×n degree of divergence (1 - entropy)
%
%   Notes:
%       Entropy weighting gives higher weights to indicators with greater
%       dispersion (more information content). It is purely data-driven and
%       does not incorporate expert preferences. For a hybrid approach,
%       combine with AHP using the formula:
%           w_combined = (w_entropy .* w_ahp) ./ sum(w_entropy .* w_ahp)
%
%   Example:
%       A = [4 7 10; 5 8 9; 6 9 8];  % 3 alternatives, 3 indicators
%       r = entropy_weight(A);
%       disp(r.weights);              % [0.42 0.35 0.23] (example)
%       disp(r.scores);               % composite scores
%
%   Reference:
%       Shannon, C.E. (1948). A Mathematical Theory of Communication.
%
%   See also: topsis, critic_weight, ahp_entropy_weight.

% ---------- 1. Input validation ----------
validateattributes(data, {'numeric'}, {'2d', 'nonempty', 'real', 'finite'}, ...
    mfilename, 'data', 1);
[m, n] = size(data);
if m < 2
    error('entropy_weight:NotEnoughRows', ...
        'At least two rows are required to compute entropy.');
end

% ---------- 2. Default arguments ----------
if nargin < 2 || isempty(benefitMask)
    benefitMask = true(1, n);
end
if nargin < 3 || isempty(normMethod)
    normMethod = 'minmax';
end

validateattributes(benefitMask, {'logical'}, {'vector', 'numel', n}, ...
    mfilename, 'benefitMask', 2);
normMethod = validatestring(normMethod, {'minmax', 'zscore', 'proportion'}, ...
    mfilename, 'normMethod', 3);

% ---------- 3. Normalization (direction-aware) ----------
normalized = zeros(m, n);
switch lower(normMethod)
    case 'minmax'
        for j = 1:n
            col = data(:, j);
            cmin = min(col);
            cmax = max(col);
            if cmax == cmin
                normalized(:, j) = 0;  % constant column → zero weight
            elseif benefitMask(j)
                normalized(:, j) = (col - cmin) ./ (cmax - cmin);
            else
                normalized(:, j) = (cmax - col) ./ (cmax - cmin);
            end
        end
    case 'zscore'
        for j = 1:n
            col = data(:, j);
            cmu = mean(col);
            csigma = std(col);
            if csigma == 0
                normalized(:, j) = 0;
            else
                z = (col - cmu) ./ csigma;
                if benefitMask(j)
                    normalized(:, j) = z - min(z);
                else
                    normalized(:, j) = max(z) - z;
                end
            end
        end
    case 'proportion'
        for j = 1:n
            col = data(:, j);
            csum = sum(col);
            if csum == 0
                normalized(:, j) = 0;
            elseif benefitMask(j)
                normalized(:, j) = col ./ csum;
            else
                rcol = max(col) + min(col) - col;
                normalized(:, j) = rcol ./ sum(rcol);
            end
        end
end

% ---------- 4. Shift non-negative (entropy requires p>=0) ----------
% add a small shift per column so min becomes a tiny positive number
for j = 1:n
    cmin = min(normalized(:, j));
    if cmin <= 0
        normalized(:, j) = normalized(:, j) - cmin + 1e-10;
    end
end

% ---------- 5. Compute entropy ----------
colsums = sum(normalized, 1);
colsums(colsums == 0) = 1;
proportions = normalized ./ colsums;

k = 1 / log(m);
entropy = -k * sum(proportions .* log(max(proportions, 1e-16)), 1);

% ---------- 6. Divergence → weights ----------
divergence = 1 - entropy;
% Constant indicators get zero weight
divergence(divergence < 0) = 0;
if sum(divergence) == 0
    error('entropy_weight:ZeroDivergence', ...
        'All indicators have zero information. Cannot determine weights.');
end
weights = divergence ./ sum(divergence);

% ---------- 7. Weighted scores ----------
scores = normalized * weights';
scores = scores ./ max(abs(scores));  % scale to reasonable range

% ---------- 8. Assemble output ----------
result.weights    = weights;
result.scores     = scores;
result.normalized = normalized;
result.entropy    = entropy;
result.divergence = divergence;
result.normMethod = normMethod;

end
