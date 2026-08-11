function result = dbscan(data, epsilon, minPts, normMethod)
%DBSCAN  Density-Based Spatial Clustering of Applications with Noise.
%   result = DBSCAN(data, epsilon, minPts) performs density-based
%   clustering. Points are classified as core, border, or noise.
%
%   result = DBSCAN(data, epsilon, minPts, normMethod) specifies the
%   normalization method applied before clustering.
%
%   Inputs:
%       data        - m×p matrix, m observations × p features
%       epsilon     - neighborhood radius (must be > 0)
%       minPts      - minimum points to form a dense region (≥ 2)
%       normMethod  - 'none' (default), 'zscore', or 'minmax'
%
%   Outputs:
%       result.labels       - m×1 cluster labels (0 = noise, 1..K = clusters)
%       result.nClusters    - number of clusters found (excluding noise)
%       result.nNoise       - number of noise points
%       result.corePoints   - logical m×1, true if point is a core point
%       result.epsilon      - epsilon value used
%       result.minPts       - minPts value used
%
%   Notes:
%       - DBSCAN does NOT require specifying the number of clusters.
%         It discovers clusters of arbitrary shape and handles noise.
%       - Choosing epsilon: use the k-distance plot. Plot sorted distances
%         to the k-th nearest neighbor (k ≈ minPts) and pick epsilon at
%         the "elbow" or "knee" of the curve.
%       - DBSCAN struggles with varying-density clusters. For such data,
%         consider OPTICS or HDBSCAN.
%       - This is a manual implementation for pedagogy. For production
%         use, consider MATLAB's dbscan() in Statistics Toolbox (R2019a+).
%
%   Example:
%       X = [randn(50,2)+2; randn(50,2)-2];
%       r = dbscan(X, 1.0, 5, 'zscore');
%       gscatter(X(:,1), X(:,2), r.labels);
%       fprintf('Clusters: %d, Noise: %d\n', r.nClusters, r.nNoise);
%
%   Reference:
%       Ester et al. (1996). A density-based algorithm for discovering
%       clusters in large spatial databases.
%
%   See also: gmm_clustering (Python).

% ---------- 1. Input validation ----------
validateattributes(data, {'numeric'}, {'2d','nonempty','real','finite'}, ...
    mfilename, 'data', 1);
[m, p] = size(data);

validateattributes(epsilon, {'numeric'}, {'scalar','positive','real'}, ...
    mfilename, 'epsilon', 2);

validateattributes(minPts, {'numeric'}, ...
    {'scalar','integer','>=',2}, mfilename, 'minPts', 3);

if nargin < 4 || isempty(normMethod)
    normMethod = 'none';
end
normMethod = validatestring(normMethod, {'none','zscore','minmax'}, ...
    mfilename, 'normMethod', 4);

% ---------- 2. Normalization ----------
switch lower(normMethod)
    case 'zscore'
        sd = std(data, 0, 1);
        sd(sd == 0) = 1;
        dataNorm = (data - mean(data, 1)) ./ sd;
    case 'minmax'
        cmin = min(data, [], 1);
        cmax = max(data, [], 1);
        dr = cmax - cmin; dr(dr == 0) = 1;
        dataNorm = (data - cmin) ./ dr;
    otherwise
        dataNorm = data;
end

% ---------- 3. Compute pairwise distances ----------
D = pdist2(dataNorm, dataNorm);

% ---------- 4. Find core points ----------
neighborCount = sum(D <= epsilon, 2);
isCore = neighborCount >= minPts;

% ---------- 5. Expand clusters ----------
labels = zeros(m, 1);  % 0 = unvisited
clusterID = 0;

for i = 1:m
    if labels(i) ~= 0
        continue;  % already visited
    end
    
    if ~isCore(i)
        labels(i) = 0;  % noise (tentatively)
        continue;
    end
    
    % Start a new cluster
    clusterID = clusterID + 1;
    seeds = find(D(i, :) <= epsilon)';
    labels(i) = clusterID;
    
    k = 1;
    while k <= numel(seeds)
        j = seeds(k);
        if labels(j) == 0
            labels(j) = clusterID;  % change noise → border
        end
        if labels(j) ~= 0
            % Already assigned to this or another cluster
            k = k + 1;
            continue;
        end
        labels(j) = clusterID;
        if isCore(j)
            % Expand neighborhood
            newNeighbors = find(D(j, :) <= epsilon)';
            seeds = [seeds; newNeighbors]; %#ok<AGROW>
        end
        k = k + 1;
    end
end

% ---------- 6. Assemble output ----------
result.labels    = labels;
result.nClusters = numel(unique(labels(labels > 0)));
result.nNoise    = sum(labels == 0);
result.corePoints = isCore;
result.epsilon   = epsilon;
result.minPts    = minPts;
result.normMethod = normMethod;

end
