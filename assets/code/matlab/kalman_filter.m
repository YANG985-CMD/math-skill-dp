function result = kalman_filter(observations, varargin)
%KALMAN_FILTER  Discrete Kalman filter for state estimation.
%   result = KALMAN_FILTER(observations) applies a simple local-level
%   Kalman filter with auto-estimated noise parameters.
%
%   result = KALMAN_FILTER(observations, 'Param1', Value1, ...) accepts:
%       'A'    - n×n state transition matrix (default: eye(n))
%       'H'    - m×n observation matrix (default: eye(n))
%       'Q'    - n×n process noise covariance (default: 0.01*eye)
%       'R'    - m×m measurement noise covariance (default: var(Y)*eye)
%       'x0'   - n×1 initial state (default: first observation)
%       'P0'   - n×n initial covariance (default: eye(n))
%
%   Inputs:
%       observations - T×m matrix of T observations, m measurement channels
%
%   Outputs:
%       result.x_filtered   - T×n filtered state estimates
%       result.x_predicted  - T×n one-step-ahead predictions
%       result.P_filtered   - n×n×T filtered covariance
%       result.P_predicted  - n×n×T predicted covariance
%       result.K_gain       - n×m×T Kalman gain (diagnostic)
%       result.innovation   - T×m innovation (observation - prediction)
%       result.innovationCov - m×m×T innovation covariance (diagnostic)
%
%   Notes:
%       - Kalman filter is optimal for linear-Gaussian systems. For
%         nonlinear problems, use Extended KF (EKF) or Unscented KF (UKF).
%       - Check innovation sequence for whiteness — autocorrelated
%         innovations indicate model misspecification.
%       - For parameter estimation, embed parameters in the state vector
%         and use a random-walk transition.
%
%   Example:
%       % Track a 1D position from noisy measurements
%       true_pos = sin(0.1*(1:100)');
%       obs = true_pos + 0.1*randn(100,1);
%       r = kalman_filter(obs, 'A', 1, 'H', 1, 'Q', 0.001, 'R', 0.01);
%       plot(1:100, true_pos, 'b-', 1:100, r.x_filtered, 'r--');
%       legend('True', 'Filtered');
%
%   Reference:
%       Kalman, R.E. (1960). A new approach to linear filtering.
%
%   See also: particle_swarm (if using state-estimation loss).

p = inputParser;
p.addParameter('A', [], @(x) isnumeric(x) && ismatrix(x));
p.addParameter('H', [], @(x) isnumeric(x) && ismatrix(x));
p.addParameter('Q', [], @(x) isnumeric(x) && ismatrix(x));
p.addParameter('R', [], @(x) isnumeric(x) && ismatrix(x));
p.addParameter('x0', [], @(x) isnumeric(x) && isvector(x));
p.addParameter('P0', [], @(x) isnumeric(x) && ismatrix(x));
p.parse(varargin{:});
opts = p.Results;

% ---------- 1. Input validation ----------
validateattributes(observations, {'numeric'}, {'2d','nonempty','real','finite'}, ...
    mfilename, 'observations', 1);
[T, m] = size(observations);

% State dimension defaults to measurement dimension
n = m;

% ---------- 2. Set system matrices ----------
if isempty(opts.A), opts.A = eye(n); end
if isempty(opts.H), opts.H = eye(m, n); end
if isempty(opts.Q), opts.Q = 0.01 * eye(n); end
if isempty(opts.R), opts.R = var(observations, 0, 1)' .* eye(m);
    if any(isnan(opts.R(:))), opts.R = 0.1 * eye(m); end
end
if isempty(opts.x0), opts.x0 = observations(1, :)' * opts.H;
    opts.x0 = opts.x0(:); end
if isempty(opts.P0), opts.P0 = eye(n); end

A = opts.A; H = opts.H; Q = opts.Q; R = opts.R;

% Dimension checks
if size(A,1) ~= n || size(A,2) ~= n
    error('kalman_filter:ADimension', 'A must be %dx%d.', n, n);
end
if size(H,2) ~= n
    error('kalman_filter:HDimension', 'H must have %d columns.', n);
end

% ---------- 3. Kalman filter recursion ----------
x_pred = zeros(T, n);
x_filt = zeros(T, n);
P_pred = zeros(n, n, T);
P_filt = zeros(n, n, T);
K_all  = zeros(n, m, T);
innov  = zeros(T, m);
innovCov = zeros(m, m, T);

x = opts.x0(:);
P = opts.P0;

for t = 1:T
    % ---- Predict ----
    x_pred(t, :) = (A * x)';
    P = A * P * A' + Q;
    P_pred(:, :, t) = P;
    
    % ---- Update ----
    z = observations(t, :)';
    y_tilde = z - H * x_pred(t, :)';   % innovation
    S = H * P * H' + R;                 % innovation covariance
    K = P * H' / S;                     % Kalman gain
    
    x = x_pred(t, :)' + K * y_tilde;
    P = (eye(n) - K * H) * P;
    % Ensure symmetry
    P = (P + P') / 2;
    
    % Store
    x_filt(t, :) = x';
    P_filt(:, :, t) = P;
    K_all(:, :, t) = K;
    innov(t, :) = y_tilde';
    innovCov(:, :, t) = S;
end

% ---------- 4. Assemble output ----------
result.x_filtered    = x_filt;
result.x_predicted   = x_pred;
result.P_filtered    = P_filt;
result.P_predicted   = P_pred;
result.K_gain        = K_all;
result.innovation    = innov;
result.innovationCov = innovCov;
result.Q             = Q;
result.R             = R;
result.T             = T;
result.n             = n;
result.m             = m;

end
