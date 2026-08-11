function result = dijkstra(adjMatrix, sourceNode)
%DIJKSTRA  Dijkstra's shortest-path algorithm for non-negative edge weights.
%   result = DIJKSTRA(adjMatrix, sourceNode) finds the shortest paths
%   from sourceNode to all other nodes in a weighted graph.
%
%   result = DIJKSTRA(adjMatrix, sourceNode) with sourceNode=[] returns
%   the all-pairs shortest-path distance matrix using repeated Dijkstra.
%
%   Inputs:
%       adjMatrix  - n×n adjacency matrix (adjMatrix(i,j) = edge weight i→j)
%                    Use 0 or Inf for no edge.
%       sourceNode - scalar node index (1-based), or [] for all-pairs
%
%   Outputs:
%       result.distances  - 1×n or n×n shortest-path distances
%       result.predecessors - 1×n predecessor array (reconstruct paths)
%       result.exists      - logical, true if a path exists
%
%   Notes:
%       - All edge weights must be ≥ 0. For negative weights, use the
%         Bellman-Ford algorithm.
%       - For large sparse graphs, prefer MATLAB's built-in graph object:
%           G = digraph(adjMatrix); d = distances(G, sourceNode);
%       - The predecessor array can reconstruct the path:
%           path = []; u = target; while u > 0; path=[u path]; u=pred(u); end
%
%   Example:
%       % 5-node graph
%       A = [0 4 0 0 0; 0 0 1 10 0; 0 0 0 0 3; 0 0 0 0 1; 0 0 0 0 0];
%       r = dijkstra(A, 1);
%       fprintf('Distance 1→5 = %.0f\n', r.distances(5));
%
%   See also: graph (MATLAB built-in), max_flow (for flow networks).

% ---------- 1. Input validation ----------
validateattributes(adjMatrix, {'numeric'}, {'2d','square','real'}, ...
    mfilename, 'adjMatrix', 1);
n = size(adjMatrix, 1);

% ---------- 2. Handle all-pairs mode ----------
if isempty(sourceNode)
    D = zeros(n);
    for s = 1:n
        r = dijkstraSingle(adjMatrix, s, n);
        D(s, :) = r.distances;
    end
    result.distances    = D;
    result.predecessors = [];  % not meaningful for all-pairs
    result.exists       = all(D(:) < Inf);
    return;
end

validateattributes(sourceNode, {'numeric'}, {'scalar','integer','>=',1,'<=',n}, ...
    mfilename, 'sourceNode', 2);

result = dijkstraSingle(adjMatrix, sourceNode, n);

end

function result = dijkstraSingle(adjMatrix, source, n)
% Core Dijkstra for a single source node.

dist = Inf(1, n);
dist(source) = 0;
pred = zeros(1, n);
visited = false(1, n);

% Replace zeros with Inf (except source self-loop conceptually)
W = adjMatrix;
W(W == 0) = Inf;
for i = 1:n, W(i,i) = 0; end

for iter = 1:n
    % Find unvisited node with minimum distance
    unvisitedDist = dist;
    unvisitedDist(visited) = Inf;
    [minDist, u] = min(unvisitedDist);
    
    if minDist == Inf
        break;  % remaining nodes are unreachable
    end
    
    visited(u) = true;
    
    % Relax neighbors
    for v = 1:n
        if ~visited(v) && W(u,v) < Inf
            alt = dist(u) + W(u,v);
            if alt < dist(v)
                dist(v) = alt;
                pred(v) = u;
            end
        end
    end
end

result.distances    = dist;
result.predecessors = pred;
result.exists       = all(dist(1:min(n, find(~visited,1)-1)) < Inf);

end
