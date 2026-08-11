function result = critic_weight(data, benefitMask)
%CRITIC_WEIGHT  CRiteria Importance Through Intercriteria Correlation.
%   result = CRITIC_WEIGHT(data) computes objective weights using the
%   CRITIC method that considers both contrast intensity (standard
%   deviation) and conflict (correlation) between criteria.
%
%   result = CRITIC_WEIGHT(data, benefitMask) sets indicator direction
%   for min-max normalization.
%
%   Inputs:
%       data        - m×n matrix, m alternatives × n criteria
%       benefitMask - 1×n logical, true=benefit, false=cost (default: all true)
%
%   Outputs:
%       result.weights     - 1×n CRITIC weight vector
%       result.scores      - m×1 weighted composite scores
%       result.std         - 1×n standard deviation per criterion
%       result.conflict    - 1×n conflict measure per criterion (= sum_j(1-r_ij))
%       result.infoAmount  - 1×n information amount per criterion
%       result.corrMatrix  - n×n correlation matrix
%
%   Notes:
%       - CRITIC is superior to entropy weight when criteria are
%         correlated, as it explicitly penalizes redundant indicators.
%       - If your data contains both benefit and cost criteria, set
%         benefitMask appropriately. CRITIC uses min-max normalization
%         which is direction-sensitive.
%
%   Example:
%       A = randn(20, 5);  % 20 alternatives, 5 criteria
%       r = critic_weight(A);
%       bar(r.weights);
%       title('CRITIC Weights');
%
%   Reference:
%       Diakoulaki et al. (1995). Determining objective weights in
%       multiple criteria problems: The CRITIC method.
%
%   See also: entropy_weight, topsis, vikor.

% ---------- 1. Input validation ----------
validateattributes(data, {'numeric'}, {'2d','nonempty','real','finite'}, ...
    mfilename, 'data', 1);
[m, n] = size(data);
if m < 3
    error('critic_weight:TooFewRows', ...
        'At least 3 rows required for correlation estimation.');
end

if nargin < 2 || isempty(benefitMask)
    benefitMask = true(1, n);
end
validateattributes(benefitMask, {'logical'}, {'vector','numel',n}, ...
    mfilename, 'benefitMask', 2);

% ---------- 2. Min-max normalization (direction-aware) ----------
normData = zeros(m, n);
for j = 1:n
    col = data(:, j);
    cmin = min(col);
    cmax = max(col);
    if cmax == cmin
        normData(:, j) = 0;
    elseif benefitMask(j)
        normData(:, j) = (col - cmin) ./ (cmax - cmin);
    else
        normData(:, j) = (cmax - col) ./ (cmax - cmin);
    end
end

% ---------- 3. Contrast intensity (standard deviation) ----------
stdVec = std(normData, 0, 1);
stdVec(stdVec == 0) = eps;  % avoid zero weight

% ---------- 4. Conflict measure (1 - correlation) ----------
corrMat = corrcoef(normData);
% Ensure symmetric; handle NaN from constant columns
corrMat(isnan(corrMat)) = 0;

conflict = zeros(1, n);
for j = 1:n
    conflict(j) = sum(1 - abs(corrMat(j, :)));
end

% ---------- 5. Information amount & weights ----------
infoAmount = stdVec .* conflict;
if sum(infoAmount) == 0
    error('critic_weight:ZeroInfo', 'All criteria have zero information amount.');
end
weights = infoAmount ./ sum(infoAmount);

% ---------- 6. Weighted scores ----------
scores = normData * weights';
scores = scores ./ max(abs(scores));

% ---------- 7. Assemble output ----------
result.weights    = weights;
result.scores     = scores;
result.std        = stdVec;
result.conflict   = conflict;
result.infoAmount = infoAmount;
result.corrMatrix = corrMat;

end
