function result = topsis(data, weights, benefitMask, normMethod)
%TOPSIS  Technique for Order Preference by Similarity to Ideal Solution.
%   result = TOPSIS(data) ranks alternatives using equal weights and
%   benefit-direction defaults for all indicators.
%
%   result = TOPSIS(data, weights) applies custom weights (will be
%   normalized to sum 1).
%
%   result = TOPSIS(data, weights, benefitMask) sets indicator direction
%   where benefitMask(j)=true means larger-is-better (benefit), and
%   false means smaller-is-better (cost).
%
%   result = TOPSIS(data, weights, benefitMask, normMethod) selects
%   normalization. Options:
%       'vector'   – vector normalization (default, most common)
%       'minmax'   – min-max normalization to [0,1]
%       'sum'      – sum normalization
%       'zscore'   – z-score standardization
%
%   Inputs:
%       data        - m×n matrix of m alternatives × n indicators
%       weights     - 1×n weight vector (default: equal weights)
%       benefitMask - 1×n logical, true=benefit, false=cost (default: all true)
%       normMethod  - char, normalization strategy (default: 'vector')
%
%   Outputs:
%       result.scores       - m×1 relative closeness scores ∈ [0,1]
%       result.ranking      - m×1 integer ranking (1 = best)
%       result.idealBest    - 1×n ideal-best vector
%       result.idealWorst   - 1×n ideal-worst vector
%       result.distBest     - m×1 distance to ideal-best
%       result.distWorst    - m×1 distance to ideal-worst
%       result.normalized   - m×n normalized decision matrix
%       result.weighted     - m×n weighted normalized matrix
%
%   Example:
%       A = [4 7 10; 5 8 9; 6 9 8];  % 3 alternatives, 3 indicators
%       w = [0.3 0.4 0.3];
%       bm = [true true false];       % first two benefit, third cost
%       r = topsis(A, w, bm);
%       disp(r.scores);               % closeness scores
%       disp(r.ranking);              % ranks
%
%   Reference:
%       Hwang & Yoon (1981). Multiple Attribute Decision Making.
%
%   See also: entropy_weight, vikor, critic_weight.

% ---------- 1. Input validation ----------
validateattributes(data, {'numeric'}, {'2d', 'nonempty', 'real', 'finite'}, ...
    mfilename, 'data', 1);
[m, n] = size(data);
if m < 2
    error('topsis:NotEnoughAlternatives', ...
        'At least two alternatives are required.');
end

% ---------- 2. Default arguments ----------
if nargin < 2 || isempty(weights)
    weights = ones(1, n);
end
if nargin < 3 || isempty(benefitMask)
    benefitMask = true(1, n);
end
if nargin < 4 || isempty(normMethod)
    normMethod = 'vector';
end

validateattributes(weights, {'numeric'}, {'vector', 'numel', n, ...
    'nonnegative'}, mfilename, 'weights', 2);
validateattributes(benefitMask, {'logical'}, {'vector', 'numel', n}, ...
    mfilename, 'benefitMask', 3);
normMethod = validatestring(normMethod, {'vector', 'minmax', 'sum', 'zscore'}, ...
    mfilename, 'normMethod', 4);

% Weights must not be all zero
if sum(weights) == 0
    error('topsis:ZeroWeights', 'Sum of weights must be positive.');
end
weights = weights(:)' ./ sum(weights);

% ---------- 3. Normalization ----------
switch lower(normMethod)
    case 'vector'
        vnorm = sqrt(sum(data .^ 2, 1));
        vnorm(vnorm == 0) = 1;  % avoid division by zero
        normData = data ./ vnorm;
    case 'minmax'
        cmin = min(data, [], 1);
        cmax = max(data, [], 1);
        drange = cmax - cmin;
        drange(drange == 0) = 1;  % constant columns → unchanged
        normData = (data - cmin) ./ drange;
    case 'sum'
        csum = sum(data, 1);
        csum(csum == 0) = 1;
        normData = data ./ csum;
    case 'zscore'
        cmu = mean(data, 1);
        csigma = std(data, 0, 1);
        csigma(csigma == 0) = 1;
        normData = (data - cmu) ./ csigma;
end

% ---------- 4. Weighted normalized matrix ----------
weighted = normData .* weights;

% ---------- 5. Ideal solutions ----------
idealBest  = zeros(1, n);
idealWorst = zeros(1, n);
for j = 1:n
    col = weighted(:, j);
    if benefitMask(j)
        idealBest(j)  = max(col);
        idealWorst(j) = min(col);
    else
        idealBest(j)  = min(col);
        idealWorst(j) = max(col);
    end
end

% ---------- 6. Distances and scores ----------
distBest  = sqrt(sum((weighted - idealBest) .^ 2, 2));
distWorst = sqrt(sum((weighted - idealWorst) .^ 2, 2));

denom = distBest + distWorst;
denom(denom == 0) = 1;  % degenerate case
scores = distWorst ./ denom;

[~, ranking] = sort(scores, 'descend');

% ---------- 7. Assemble output ----------
result.scores      = scores;
result.ranking     = ranking;
result.idealBest   = idealBest;
result.idealWorst  = idealWorst;
result.distBest    = distBest;
result.distWorst   = distWorst;
result.normalized  = normData;
result.weighted    = weighted;
result.normMethod  = normMethod;

end
