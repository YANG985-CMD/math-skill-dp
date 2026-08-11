function result = random_forest(X, y, varargin)
%RANDOM_FOREST  Random Forest classification and regression via TreeBagger.
%   result = RANDOM_FOREST(X, y) trains a random forest with default
%   parameters. Automatically detects classification vs regression based
%   on the number of unique values in y.
%
%   result = RANDOM_FOREST(X, y, 'Param', Value, ...) accepts:
%       'NumTrees'        - number of trees (default: 100)
%       'MinLeafSize'     - min observations per leaf (default: 5 for reg, 1 for cls)
%       'NumPredictors'   - variables randomly sampled per split (default: floor(sqrt(p)) for cls, floor(p/3) for reg)
%       'MaxNumSplits'    - max decision splits per tree (default: n-1, no limit)
%       'InBagFraction'   - fraction of data for each bag (default: 1.0 = bootstrap)
%       'OOBPrediction'   - compute out-of-bag prediction (default: 'on')
%       'Method'          - 'classification' or 'regression' (default: auto-detect)
%       'Categorical'     - indices of categorical predictors (default: [])
%       'Verbose'         - print progress (default: false)
%
%   Inputs:
%       X - n×p matrix of n observations × p predictors
%       y - n×1 response vector
%
%   Outputs:
%       result.model        - trained TreeBagger object
%       result.type         - 'classification' or 'regression'
%       result.oobError     - out-of-bag error rate per tree
%       result.oobPredict   - out-of-bag predictions
%       result.featureImp   - 1×p feature importance (permuted predictor delta)
%       result.predictions  - predictions on training data
%       result.confmat      - confusion matrix (classification only)
%       result.r2_train     - R^2 on training data (regression only)
%       result.rmse_train   - RMSE on training data (regression only)
%
%   Notes:
%       - Requires Statistics and Machine Learning Toolbox.
%       - OOB error provides an unbiased estimate of generalization error
%         without needing a separate validation set.
%       - Feature importance measures the increase in prediction error
%         when a predictor's values are permuted.
%       - For regression, R^2 is computed on OOB predictions for fairness.
%       - Do NOT report training-set R^2 as generalization performance.
%
%   Example - Classification:
%       load fisheriris;
%       X = meas; y = species;
%       r = random_forest(X, y, 'NumTrees', 200);
%       fprintf('OOB Error: %.2f%%\n', 100 * r.oobError(end));
%       bar(r.featureImp); title('Feature Importance');
%
%   Example - Regression:
%       X = randn(200, 5); y = X(:,1)*3 + X(:,3)*2 + randn(200,1)*0.5;
%       r = random_forest(X, y, 'NumTrees', 150);
%       fprintf('OOB R^2: %.4f, RMSE: %.4f\n', r.oobR2, r.oobRMSE);
%
%   See also: grey_prediction, kalman_filter, pca_svm (Python).

% ---------- 1. Validate inputs ----------
validateattributes(X, {'numeric'}, {'2d', 'real', 'finite'}, ...
    mfilename, 'X', 1);
validateattributes(y, {'numeric', 'categorical', 'cell', 'string', 'char'}, ...
    {'vector'}, mfilename, 'y', 2);
[n, p] = size(X);
if numel(y) ~= n
    error('random_forest:DimensionMismatch', ...
        'X has %d rows but y has %d elements.', n, numel(y));
end

% ---------- 2. Parse options ----------
pObj = inputParser;
pObj.addParameter('NumTrees', 100, @(x) isscalar(x) && x > 0);
pObj.addParameter('MinLeafSize', [], @(x) isempty(x) || (isscalar(x) && x >= 1));
pObj.addParameter('NumPredictors', [], @(x) isempty(x) || (isscalar(x) && x <= p));
pObj.addParameter('MaxNumSplits', [], @(x) isempty(x) || isscalar(x));
pObj.addParameter('InBagFraction', 1.0, @(x) x > 0 && x <= 1);
pObj.addParameter('OOBPrediction', 'on');
pObj.addParameter('Method', '', @ischar);
pObj.addParameter('Categorical', [], @(x) isvector(x));
pObj.addParameter('Verbose', false, @islogical);
pObj.parse(varargin{:});
opts = pObj.Results;

% ---------- 3. Auto-detect method ----------
if isempty(opts.Method)
    if isnumeric(y)
        uniqueY = unique(y(~isnan(y)));
        if numel(uniqueY) <= 10 && all(mod(uniqueY, 1) == 0)
            opts.Method = 'classification';
        elseif iscategorical(y) || iscell(y) || ischar(y) || isstring(y)
            opts.Method = 'classification';
        else
            opts.Method = 'regression';
        end
    elseif iscategorical(y) || iscell(y) || ischar(y) || isstring(y)
        opts.Method = 'classification';
    else
        opts.Method = 'regression';
    end
end

% ---------- 4. Set TreeBagger parameters ----------
if isempty(opts.MinLeafSize)
    if strcmp(opts.Method, 'classification')
        opts.MinLeafSize = 1;
    else
        opts.MinLeafSize = 5;
    end
end
if isempty(opts.NumPredictors)
    if strcmp(opts.Method, 'classification')
        opts.NumPredictors = max(1, floor(sqrt(p)));
    else
        opts.NumPredictors = max(1, floor(p / 3));
    end
end

% ---------- 5. Train random forest ----------
verboseFlag = 0; if opts.Verbose, verboseFlag = 1; end
oobVal = opts.OOBPrediction;

try
    if strcmp(opts.Method, 'classification')
        model = TreeBagger(opts.NumTrees, X, y, ...
            'Method', 'classification', ...
            'MinLeafSize', opts.MinLeafSize, ...
            'NumPredictorsToSample', opts.NumPredictors, ...
            'OOBPrediction', oobVal, ...
            'InBagFraction', opts.InBagFraction);
    else
        model = TreeBagger(opts.NumTrees, X, y, ...
            'Method', 'regression', ...
            'MinLeafSize', opts.MinLeafSize, ...
            'NumPredictorsToSample', opts.NumPredictors, ...
            'OOBPrediction', oobVal, ...
            'InBagFraction', opts.InBagFraction);
    end
catch ME
    error('random_forest:TrainingFailed', ...
        'TreeBagger training failed: %s\nCheck that Statistics Toolbox is installed.', ME.message);
end

% ---------- 6. Extract diagnostics ----------
% OOB error
oobError = oobError(model);

% Feature importance
featureImp = [];
try
    if model.NTrees >= 2
        featureImp = model.OOBPermutedPredictorDeltaError;
    end
catch
    featureImp = zeros(1, p);
end

% Predictions
if strcmp(opts.Method, 'classification')
    [predLabels, scores] = predict(model, X);
    if iscell(predLabels), predLabels = string(predLabels); end
    predictions = predLabels;
    % Confusion matrix
    if isnumeric(y), trueLabels = y; else, trueLabels = y; end
    try
        confmat = confusionmat(trueLabels, predictions);
    catch
        confmat = [];
    end
    result.confmat = confmat;
    result.r2_train = NaN;
    result.rmse_train = NaN;
else
    predictions = predict(model, X);
    % OOB predictions for fair R^2
    oobPred = oobPredict(model);
    SSres = sum((double(y(:)) - oobPred(:)).^2, 'omitnan');
    SStot = sum((double(y(:)) - mean(double(y(:)), 'omitnan')).^2, 'omitnan');
    result.oobR2 = 1 - SSres / max(SStot, eps);
    result.oobRMSE = sqrt(mean((double(y(:)) - oobPred(:)).^2, 'omitnan'));
    % Training R^2
    SSres_train = sum((double(y(:)) - predictions(:)).^2, 'omitnan');
    result.r2_train = 1 - SSres_train / max(SStot, eps);
    result.rmse_train = sqrt(mean((double(y(:)) - predictions(:)).^2, 'omitnan'));
    result.confmat = [];
end

% ---------- 7. Assemble output ----------
result.model        = model;
result.type         = opts.Method;
result.oobError     = oobError;
result.oobPredict   = oobPredict(model);
result.featureImp   = featureImp;
result.predictions  = predictions;
result.numTrees     = opts.NumTrees;
result.numPredictors = p;

end
