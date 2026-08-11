function result = grey_prediction(series, forecastSteps, checkData)
%GREY_PREDICTION  Grey Model GM(1,1) for small-sample trend forecasting.
%   result = GREY_PREDICTION(series) fits a GM(1,1) model and returns
%   one-step-ahead forecast.
%
%   result = GREY_PREDICTION(series, forecastSteps) forecasts N steps.
%
%   result = GREY_PREDICTION(series, forecastSteps, checkData) enables
%   data quality pre-checks when checkData is true (default: false).
%
%   Inputs:
%       series        - column vector of non-negative observations
%       forecastSteps - number of forecast steps (default: 1)
%       checkData     - logical, run data prechecks (default: false)
%
%   Outputs:
%       result.a              - development coefficient
%       result.b              - grey action quantity
%       result.fitted         - in-sample fitted values
%       result.forecast       - out-of-sample forecasts
%       result.residuals      - fitting residuals
%       result.relativeError  - |residual| / |original|
%       result.posteriorErrorRatio - C = S_residual / S_series (越小越好)
%       result.smallErrorProbability - P = P(|e - mean(e)| < 0.6745*Sx)
%       result.grade          - model precision grade:
%                               'A' (优秀), 'B' (合格), 'C' (勉强),
%                               'D' (不合格, 不可用于预测)
%
%   Model Precision Grade (国家标准):
%       Grade  P         C
%       A      >0.95     <0.35
%       B      >0.80     <0.50
%       C      >0.70     <0.65
%       D      ≤0.70     ≥0.65  → 模型不合格, 不可用于预测!
%
%   Notes:
%       - GM(1,1) requires non-negative data. If your series contains
%         negatives, apply a shift transformation first.
%       - Development coefficient |a| should be < 0.3 for short-term
%         forecasting. 0.3 ≤ |a| < 0.5 is acceptable for very short term.
%         |a| ≥ 0.5 indicates the model is unsuitable.
%       - Suitable for sample sizes of 4-20 observations.
%
%   Example:
%       sales = [156 174 198 215 240 268]';
%       r = grey_prediction(sales, 3, true);
%       fprintf('Grade: %s, a=%.4f\n', r.grade, r.a);
%       disp(r.forecast);  % next 3 periods
%
%   Reference:
%       Deng, J.L. (1982). Control problems of grey systems.
%
%   See also: gm11_markov (灰色-马尔可夫组合预测)

% ---------- 1. Input validation ----------
validateattributes(series, {'numeric'}, {'vector', 'nonempty', 'real', 'finite'}, ...
    mfilename, 'series', 1);
x0 = series(:);
n = numel(x0);

if n < 4
    error('grey_prediction:TooFewPoints', ...
        'GM(1,1) requires at least 4 data points. Got %d.', n);
end

if nargin < 2 || isempty(forecastSteps)
    forecastSteps = 1;
end
if nargin < 3 || isempty(checkData)
    checkData = false;
end

validateattributes(forecastSteps, {'numeric'}, ...
    {'scalar', 'integer', 'positive', '<=', 50}, ...
    mfilename, 'forecastSteps', 2);

% ---------- 2. Data prechecks ----------
if checkData
    if any(x0 < 0)
        warning('grey_prediction:NegativeData', ...
            ['Series contains negative values. GM(1,1) requires ' ...
             'non-negative data. Consider adding a constant shift.']);
    end
    % Quasi-smoothness check: ρ(k) = x0(k)/x1(k-1) → should < 0.5 for k>3
    x1 = cumsum(x0);
    rho = x0(4:end) ./ x1(3:end-1);
    if any(rho >= 0.5)
        warning('grey_prediction:NotQuasiSmooth', ...
            'Data may not satisfy quasi-smoothness condition (ρ ≥ 0.5).');
    end
    % Level ratio check: σ(k) = x0(k-1)/x0(k) → should ∈ (e^{-2/(n+1)}, e^{2/(n+1)})
    sigma = x0(1:end-1) ./ x0(2:end);
    lb = exp(-2/(n+1));
    ub = exp(2/(n+1));
    if any(sigma < lb | sigma > ub)
        warning('grey_prediction:LevelRatioOutOfRange', ...
            'Level ratios outside admissible range [%.4f, %.4f].', lb, ub);
    end
end

% ---------- 3. Accumulate and build B, Y ----------
x1 = cumsum(x0);
B = [-0.5 * (x1(1:end-1) + x1(2:end)), ones(n-1, 1)];
Y = x0(2:end);

% ---------- 4. Least-squares estimate of [a; b] ----------
params = B \ Y;
a = params(1);
b = params(2);

% ---------- 5. Time response function ----------
x0_1 = x0(1);
cumFcn = @(k) (x0_1 - b/a) * exp(-a * k) + b/a;

% ---------- 6. Fitted values (inverse accumulation) ----------
fitted = zeros(n, 1);
fitted(1) = x0(1);
for k = 2:n
    fitted(k) = cumFcn(k-1) - cumFcn(k-2);
end

% ---------- 7. Forecast ----------
forecast = zeros(forecastSteps, 1);
for k = 1:forecastSteps
    forecast(k) = cumFcn(n + k - 1) - cumFcn(n + k - 2);
end

% ---------- 8. Diagnostics ----------
residuals = x0 - fitted;
relErr = abs(residuals) ./ max(abs(x0), 1e-10);

% Posterior error ratio C and small error probability P
S1 = std(x0);
S2 = std(residuals);
posteriorErrorRatio = S2 / max(S1, 1e-10);

threshold = 0.6745 * S1;
smallErrorProbability = mean(abs(residuals - mean(residuals)) < threshold);

% ---------- 9. Grade model quality ----------
grade = gradeModel(posteriorErrorRatio, smallErrorProbability);

% Development coefficient validity
aValid = abs(a) < 0.5;

% ---------- 10. Assemble output ----------
result.a                     = a;
result.b                     = b;
result.fitted                = fitted;
result.forecast              = forecast;
result.residuals             = residuals;
result.relativeError         = relErr;
result.posteriorErrorRatio   = posteriorErrorRatio;
result.smallErrorProbability = smallErrorProbability;
result.grade                 = grade;
result.aValid                = aValid;

end

function grade = gradeModel(C, P)
% Assign model grade according to Chinese national standard.
if P > 0.95 && C < 0.35
    grade = 'A';  % 优秀
elseif P > 0.80 && C < 0.50
    grade = 'B';  % 合格
elseif P > 0.70 && C < 0.65
    grade = 'C';  % 勉强
else
    grade = 'D';  % 不合格
end
end
