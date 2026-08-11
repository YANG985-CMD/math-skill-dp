function result = nsga2(objectiveFcns, bounds, options)
%NSGA2  Nondominated Sorting Genetic Algorithm II for multi-objective optimization.
%   result = NSGA2(objectiveFcns, bounds) minimizes multiple objectives
%   simultaneously over bounded variables.
%
%   result = NSGA2(objectiveFcns, bounds, options) passes custom options:
%       options.popSize      - population size (default: 50)
%       options.maxGen       - max generations (default: 100)
%       options.pCrossover   - crossover probability (default: 0.9)
%       options.pMutation    - mutation probability (default: 0.1)
%       options.etaC         - SBX crossover index (default: 20)
%       options.etaM         - polynomial mutation index (default: 20)
%       options.verbose      - print progress (default: false)
%
%   Inputs:
%       objectiveFcns - cell array of function handles, each returning scalar
%                       Example: {@(x) x(1)^2, @(x) (x(2)-2)^2}
%       bounds        - n×2 matrix [lower, upper] per decision variable
%
%   Outputs:
%       result.paretoFront    - numSol×numObj Pareto-optimal objective values
%       result.paretoSet      - numSol×nvars corresponding decision vectors
%       result.frontRanks     - numSol×1 front rank (1 = first Pareto front)
%       result.crowdingDist   - numSol×1 crowding distance (diversity measure)
%       result.history        - struct with per-generation stats:
%           .nondominated     - number of nondominated solutions per gen
%           .hypervolume      - approximate hypervolume per gen
%           .spread           - solution spread per gen
%
%   Notes:
%       - This is a pedagogical implementation of NSGA-II. For production
%         use, consider MATLAB's gamultiobj in Global Optimization Toolbox.
%       - NSGA-II sorts by nondomination rank, then by crowding distance
%         within each rank to maintain diversity.
%       - All objectives are assumed to be minimized. For maximization,
%         negate the objective in the function handle.
%       - Report the full Pareto front, not a single solution, unless a
%         compromise selection rule is explicitly stated.
%
%   Example:
%       f1 = @(x) x(1)^2 + x(2)^2;
%       f2 = @(x) (x(1)-2)^2 + (x(2)-2)^2;
%       bnd = [-5 5; -5 5];
%       opts.popSize = 100; opts.maxGen = 80;
%       r = nsga2({f1, f2}, bnd, opts);
%       scatter(r.paretoFront(:,1), r.paretoFront(:,2));
%       xlabel('f1'); ylabel('f2'); title('Pareto Front');
%
%   Reference:
%       Deb et al. (2002). A fast and elitist multiobjective genetic
%       algorithm: NSGA-II.
%
%   See also: genetic_algorithm, particle_swarm, vns.

% ---------- 1. Parse options ----------
if nargin < 3, options = struct(); end
if ~isfield(options, 'popSize'),      options.popSize      = 50;    end
if ~isfield(options, 'maxGen'),       options.maxGen       = 100;   end
if ~isfield(options, 'pCrossover'),   options.pCrossover   = 0.9;   end
if ~isfield(options, 'pMutation'),    options.pMutation    = 0.1;   end
if ~isfield(options, 'etaC'),         options.etaC         = 20;    end
if ~isfield(options, 'etaM'),         options.etaM         = 20;    end
if ~isfield(options, 'verbose'),      options.verbose      = false; end

% ---------- 2. Validate ----------
validateattributes(objectiveFcns, {'cell'}, {'vector', 'nonempty'}, ...
    mfilename, 'objectiveFcns', 1);
validateattributes(bounds, {'numeric'}, {'2d', 'ncols', 2, 'real'}, ...
    mfilename, 'bounds', 2);

nvars  = size(bounds, 1);
nobj   = numel(objectiveFcns);
lb     = bounds(:, 1)';
ub     = bounds(:, 2)';
popSize = options.popSize;

if popSize < 4
    error('nsga2:SmallPopulation', 'Population size must be at least 4.');
end

% ---------- 3. Initialize population ----------
pop = initPopulation(popSize, nvars, lb, ub);
objVals = evaluatePopulation(pop, objectiveFcns, popSize, nobj);

% ---------- 4. History tracking ----------
hist.nondominated = zeros(options.maxGen, 1);
hist.hypervolume = zeros(options.maxGen, 1);
hist.spread = zeros(options.maxGen, 1);

% ---------- 5. NSGA-II main loop ----------
for gen = 1:options.maxGen
    % Non-dominated sorting
    [fronts, ranks, crowdDist] = nondominatedSort(objVals, popSize);
    
    % Generate offspring
    offspring = zeros(popSize, nvars);
    for i = 1:2:popSize
        % Binary tournament selection
        p1 = tournamentSelect(ranks, crowdDist);
        p2 = tournamentSelect(ranks, crowdDist);
        
        % Crossover
        if rand() < options.pCrossover
            [c1, c2] = sbxCrossover(pop(p1,:), pop(p2,:), lb, ub, options.etaC);
        else
            c1 = pop(p1,:); c2 = pop(p2,:);
        end
        
        % Mutation
        c1 = polynomialMutation(c1, lb, ub, options.etaM, options.pMutation);
        c2 = polynomialMutation(c2, lb, ub, options.etaM, options.pMutation);
        
        offspring(i, :) = c1;
        if i+1 <= popSize, offspring(i+1, :) = c2; end
    end
    
    % Evaluate offspring
    offObj = evaluatePopulation(offspring, objectiveFcns, popSize, nobj);
    
    % Merge populations
    mergedPop = [pop; offspring];
    mergedObj = [objVals; offObj];
    
    % Select next generation
    [mergedFronts, mergedRanks, mergedCrowd] = nondominatedSort(mergedObj, 2*popSize);
    [pop, objVals, ranks, crowdDist] = selectNextGen(mergedPop, mergedObj, ...
        mergedRanks, mergedCrowd, popSize);
    
    % Track stats
    hist.nondominated(gen) = sum(ranks == 1);
    [hist.hypervolume(gen), hist.spread(gen)] = ...
        computeStats(objVals(ranks == 1, :), nobj);
    
    if options.verbose && mod(gen, 10) == 0
        fprintf('Gen %d: nondominated=%d\n', gen, hist.nondominated(gen));
    end
end

% ---------- 6. Final front ----------
[finalFronts, finalRanks, finalCrowd] = nondominatedSort(objVals, popSize);

% ---------- 7. Assemble output ----------
result.paretoFront     = objVals(finalRanks == 1, :);
result.paretoSet       = pop(finalRanks == 1, :);
result.frontRanks      = finalRanks;
result.crowdingDist    = finalCrowd;
result.history         = hist;
result.options         = options;

end

% ========== Helper Functions ==========

function pop = initPopulation(popSize, nvars, lb, ub)
    pop = lb + rand(popSize, nvars) .* (ub - lb);
end

function objVals = evaluatePopulation(pop, objectiveFcns, popSize, nobj)
    objVals = zeros(popSize, nobj);
    for i = 1:popSize
        for j = 1:nobj
            objVals(i, j) = objectiveFcns{j}(pop(i, :));
        end
    end
end

function [fronts, ranks, crowdDist] = nondominatedSort(objVals, N)
    % Returns fronts as cell array, ranks as vector, crowding distances
    dominatedCount = zeros(N, 1);
    dominates = cell(N, 1);
    fronts = {};
    ranks = zeros(N, 1);
    crowdDist = zeros(N, 1);
    
    for i = 1:N
        for j = 1:N
            if i == j, continue; end
            if dominatesP(objVals(i,:), objVals(j,:))
                dominates{i}(end+1) = j;
            elseif dominatesP(objVals(j,:), objVals(i,:))
                dominatedCount(i) = dominatedCount(i) + 1;
            end
        end
        if dominatedCount(i) == 0
            if isempty(fronts), fronts{1} = []; end
            fronts{1}(end+1) = i;
            ranks(i) = 1;
        end
    end
    
    f = 1;
    while f <= numel(fronts) && ~isempty(fronts{f})
        nextFront = [];
        for i = fronts{f}
            for j = dominates{i}
                dominatedCount(j) = dominatedCount(j) - 1;
                if dominatedCount(j) == 0
                    nextFront(end+1) = j;
                    ranks(j) = f + 1;
                end
            end
        end
        f = f + 1;
        if ~isempty(nextFront)
            fronts{f} = nextFront;
        end
    end
    
    % Crowding distance within each front
    for fi = 1:numel(fronts)
        fidx = fronts{fi};
        crowdDist(fidx) = crowdingDistance(objVals(fidx, :));
    end
end

function d = dominatesP(a, b)
    % Returns true if a dominates b (a <= b in all obj, a < b in at least one)
    d = all(a <= b) && any(a < b);
end

function cd = crowdingDistance(objVals)
    [n, m] = size(objVals);
    cd = zeros(n, 1);
    for j = 1:m
        [~, idx] = sort(objVals(:, j));
        cd(idx(1)) = Inf; cd(idx(end)) = Inf;
        fRange = objVals(idx(end), j) - objVals(idx(1), j);
        if fRange == 0, continue; end
        for i = 2:n-1
            cd(idx(i)) = cd(idx(i)) + ...
                (objVals(idx(i+1), j) - objVals(idx(i-1), j)) / fRange;
        end
    end
end

function idx = tournamentSelect(ranks, crowdDist)
    cands = randi(length(ranks), 1, 2);
    if ranks(cands(1)) < ranks(cands(2))
        idx = cands(1);
    elseif ranks(cands(1)) > ranks(cands(2))
        idx = cands(2);
    else
        if crowdDist(cands(1)) > crowdDist(cands(2))
            idx = cands(1);
        else
            idx = cands(2);
        end
    end
end

function [c1, c2] = sbxCrossover(p1, p2, lb, ub, etaC)
    n = numel(p1);
    c1 = p1; c2 = p2;
    for i = 1:n
        if rand() < 0.5
            if abs(p2(i) - p1(i)) > 1e-10
                if p1(i) < p2(i)
                    y1 = p1(i); y2 = p2(i);
                else
                    y1 = p2(i); y2 = p1(i);
                end
                yl = lb(i); yu = ub(i);
                r = rand();
                beta = 1 + 2/(y2 - y1) * min(y1 - yl, yu - y2);
                alpha = 2 - beta^(-(etaC+1));
                if r <= 1/alpha
                    betaq = (r * alpha)^(1/(etaC+1));
                else
                    betaq = (1/(2 - r*alpha))^(1/(etaC+1));
                end
                c1(i) = 0.5 * (y1 + y2 - betaq*(y2 - y1));
                c2(i) = 0.5 * (y1 + y2 + betaq*(y2 - y1));
            end
        end
    end
    c1 = max(min(c1, ub), lb);
    c2 = max(min(c2, ub), lb);
end

function x = polynomialMutation(x, lb, ub, etaM, pMut)
    n = numel(x);
    for i = 1:n
        if rand() < pMut
            delta = (ub(i) - lb(i)) * (2 * rand())^(1/(etaM+1));
            if rand() < 0.5
                x(i) = x(i) - delta;
            else
                x(i) = x(i) + delta;
            end
        end
    end
    x = max(min(x, ub), lb);
end

function [pop, objVals, ranks, crowdDist] = selectNextGen(mergedPop, mergedObj, mergedRanks, mergedCrowd, popSize)
    % Select top N using non-dominated sorting and crowding distance
    [~, sortIdx] = sortrows([mergedRanks, -mergedCrowd]);
    selIdx = sortIdx(1:popSize);
    pop = mergedPop(selIdx, :);
    objVals = mergedObj(selIdx, :);
    ranks = mergedRanks(selIdx);
    crowdDist = mergedCrowd(selIdx);
end

function [hv, spread] = computeStats(objVals, nobj)
    if isempty(objVals)
        hv = 0; spread = 0; return;
    end
    % Simple hypervolume approximation using bounding-box product
    if nobj >= 2
        fmin = min(objVals, [], 1);
        fmax = max(objVals, [], 1);
        % reference point slightly beyond max
        ref = fmax + 0.1 * (fmax - fmin + 1);
        hv = prod(ref - fmin);
    else
        hv = 0;
    end
    % Spread: average distance between consecutive sorted solutions
    if nobj == 2
        [~, idx] = sort(objVals(:,1));
        sorted = objVals(idx, :);
        dists = sqrt(sum(diff(sorted).^2, 2));
        spread = mean(dists);
    else
        spread = 0;
    end
end
