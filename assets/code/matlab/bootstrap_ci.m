function result = bootstrap_ci(data, statFcn, nBoot, alpha)
%BOOTSTRAP_CI  Bootstrap confidence intervals for any statistic.
%   result = BOOTSTRAP_CI(data, statFcn) computes 95% bootstrap
%   percentile confidence intervals for the statistic returned by statFcn.
%
%   result = BOOTSTRAP_CI(data, statFcn, nBoot, alpha) specifies the
%   number of bootstrap resamples and confidence level.
%
%   Inputs:
%       data    - m×p matrix, observations × variables
%       statFcn - function handle @(x) that computes a scalar statistic
%                 from the data matrix x. Example: @(x) mean(x(:,1))
%       nBoot   - number of bootstrap resamples (default: 2000)
%       alpha   - significance level, CI = 1-alpha (default: 0.05 → 95% CI)
%
%   Outputs:
%       result.statistic - value of statFcn on the original data
%       result.ci_lower  - lower confidence bound
%       result.ci_upper  - upper confidence bound
%       result.bootstrap - nBoot×1 bootstrap replicates
%       result.bias      - bootstrap bias estimate (mean(boot)-original)
%       result.se_boot   - bootstrap standard error
%       result.alpha     - significance level used
%       result.method    - 'percentile'
%
%   Notes:
%       - Bootstrap CIs are nonparametric and avoid distributional
%         assumptions. They work for any well-behaved statistic.
%       - For small samples (n < 30), use BCa (bias-corrected and
%         accelerated) intervals instead of percentile. This can be
%         done with MATLAB's bootci(@statFcn, nBoot, data, 'type','bca').
%       - For time series data, use block bootstrap or stationary
%         bootstrap to preserve autocorrelation structure.
%
%   Example:
%       data = randn(50, 1) + 2;
%       % CI for the 90th percentile
%       r = bootstrap_ci(data, @(x) prctile(x, 90), 5000);
%       fprintf('90th percentile: %.2f [%.2f, %.2f]\n', ...
%           r.statistic, r.ci_lower, r.ci_upper);
%
%   See also: monte_carlo_simulation.

% ---------- 1. Input validation ----------
validateattributes(data, {'numeric'}, {'2d','nonempty','real'}, ...
    mfilename, 'data', 1);
validateattributes(statFcn, {'function_handle'}, {'scalar'}, ...
    mfilename, 'statFcn', 2);

[m, ~] = size(data);

if nargin < 3 || isempty(nBoot)
    nBoot = 2000;
end
if nargin < 4 || isempty(alpha)
    alpha = 0.05;
end

validateattributes(nBoot, {'numeric'}, {'scalar','integer','positive'}, ...
    mfilename, 'nBoot', 3);
validateattributes(alpha, {'numeric'}, {'scalar','>',0,'<',1}, ...
    mfilename, 'alpha', 4);

% ---------- 2. Compute original statistic ----------
try
    theta0 = statFcn(data);
catch ME
    error('bootstrap_ci:StatFcnFailed', ...
        'statFcn failed on original data: %s', ME.message);
end
validateattributes(theta0, {'numeric'}, {'scalar','real'}, ...
    mfilename, 'statistic');

% ---------- 3. Bootstrap resampling ----------
bootReps = NaN(nBoot, 1);
for b = 1:nBoot
    idx = randi(m, m, 1);
    bootSample = data(idx, :);
    bootReps(b) = statFcn(bootSample);
end

% ---------- 4. Compute CI ----------
bootReps = bootReps(~isnan(bootReps));
nValid = numel(bootReps);

ci_lower = prctile(bootReps, 100 * alpha/2);
ci_upper = prctile(bootReps, 100 * (1 - alpha/2));
biasEst  = mean(bootReps) - theta0;
seBoot   = std(bootReps);

% ---------- 5. Assemble output ----------
result.statistic = theta0;
result.ci_lower  = ci_lower;
result.ci_upper  = ci_upper;
result.bootstrap = bootReps;
result.bias      = biasEst;
result.se_boot   = seBoot;
result.alpha     = alpha;
result.method    = 'percentile';
result.nValid    = nValid;

end
