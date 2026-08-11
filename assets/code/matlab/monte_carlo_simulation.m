function result = monte_carlo_simulation(simFcn, nRuns, varargin)
%MONTE_CARLO_SIMULATION  Monte Carlo uncertainty propagation.
%   result = MONTE_CARLO_SIMULATION(simFcn, nRuns) executes the
%   simulation function simFcn nRuns times and aggregates results.
%
%   result = MONTE_CARLO_SIMULATION(simFcn, nRuns, 'Param', Value, ...):
%       'parallel'  - logical, use parfor if true (default: false)
%       'seed'      - random seed for reproducibility (default: now-based)
%       'quantiles' - vector of quantiles to report (default: [0.05 0.5 0.95])
%
%   Inputs:
%       simFcn  - function handle with NO input arguments, that returns
%                 a scalar or row vector of outputs for ONE replicate.
%                 Example: @() myModel(randn(), rand())
%       nRuns   - number of Monte Carlo replicates
%
%   Outputs:
%       result.all         - nRuns×k matrix of all replicate outputs
%       result.mean        - 1×k mean across replicates
%       result.std         - 1×k standard deviation
%       result.quantiles   - (numQ)×k quantile estimates
%       result.quantileLevels - labels for quantile rows
%       result.min95       - 1×k lower 95% confidence bound (percentile)
%       result.max95       - 1×k upper 95% confidence bound (percentile)
%       result.se_mean     - 1×k standard error of the mean
%       result.nRuns       - number of completed runs
%       result.elapsed_sec - wall-clock execution time
%
%   Notes:
%       - Monte Carlo is a sampling-based method for propagating
%         uncertainty through a model. It requires specifying input
%         distributions inside simFcn.
%       - nRuns should be large enough for stable estimates. A rule of
%         thumb: nRuns ≥ 10,000 for tail quantiles (e.g. 95th percentile).
%       - For expensive simulations, consider Latin Hypercube Sampling
%         (lhsdesign in Statistics Toolbox) to reduce required runs.
%
%   Example:
%       % Simulate project cost with uncertain labor and material
%       sim = @() (100 + 5*randn()) * (8 + rand()) + 200 * (1 + 0.1*randn());
%       r = monte_carlo_simulation(sim, 10000);
%       fprintf('Mean cost: %.0f ± %.0f [%.0f, %.0f]\n', ...
%           r.mean, r.std, r.min95, r.max95);
%
%   See also: bootstrap_ci, kalman_filter.

% ---------- 1. Parse inputs ----------
p = inputParser;
p.addParameter('parallel', false, @islogical);
p.addParameter('seed', [], @(x) isnumeric(x) && isscalar(x));
p.addParameter('quantiles', [0.025 0.25 0.5 0.75 0.975], ...
    @(x) all(x>0 & x<1));
p.parse(varargin{:});
opts = p.Results;

validateattributes(simFcn, {'function_handle'}, {'scalar'}, ...
    mfilename, 'simFcn', 1);
validateattributes(nRuns, {'numeric'}, {'scalar','integer','positive'}, ...
    mfilename, 'nRuns', 2);

% ---------- 2. Set random seed ----------
if ~isempty(opts.seed)
    rng(opts.seed);
end

% ---------- 3. Execute simulations ----------
% Run one trial to determine output dimension
try
    testOut = simFcn();
catch ME
    error('monte_carlo_simulation:SimFcnFailed', ...
        'simFcn failed on test run: %s', ME.message);
end
testOut = testOut(:)';
k = numel(testOut);

allResults = NaN(nRuns, k);
tStart = tic;

if opts.parallel
    parfor i = 1:nRuns
        out = simFcn();
        allResults(i, :) = out(:)';
    end
else
    for i = 1:nRuns
        out = simFcn();
        allResults(i, :) = out(:)';
    end
end

elapsed = toc(tStart);

% ---------- 4. Aggregate statistics ----------
allResults(allResults == Inf | allResults == -Inf) = NaN;
meanVec = mean(allResults, 1, 'omitnan');
stdVec  = std(allResults, 0, 1, 'omitnan');
seMean  = stdVec ./ sqrt(sum(~isnan(allResults), 1));

% Quantiles
qLevels = opts.quantiles(:);
if numel(qLevels) == 1
    qVals = quantile(allResults, qLevels, 1);
else
    qVals = quantile(allResults, qLevels, 1);
end

% Confidence bounds
min95 = quantile(allResults, 0.025, 1);
max95 = quantile(allResults, 0.975, 1);

% ---------- 5. Assemble output ----------
result.all       = allResults;
result.mean      = meanVec;
result.std       = stdVec;
result.quantiles = qVals;
result.quantileLevels = qLevels;
result.min95     = min95;
result.max95     = max95;
result.se_mean   = seMean;
result.nRuns     = nRuns;
result.elapsed_sec = elapsed;

end
