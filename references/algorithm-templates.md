# Algorithm Templates

Use this schema:

- Algorithm
- Best-fit task types
- Input requirements
- Output structure
- Key parameters
- What to edit for a new problem
- Failure modes
- Paper explanation pattern
- Local asset path

## MATLAB Native Templates (MATLAB-First)

### Evaluation & Ranking

| Algorithm | File | Notes |
|---|---|---|
| TOPSIS | `assets/code/matlab/topsis.m` | 4 normalization methods, input validation, degradation protection |
| Entropy Weight | `assets/code/matlab/entropy_weight.m` | 3 normalization methods, non-negative shift, zero-divergence guard |
| CRITIC Weight | `assets/code/matlab/critic_weight.m` | Contrast intensity + inter-criteria conflict, handles correlated indicators |
| VIKOR | `assets/code/matlab/vikor.m` | Compromise ranking with majority/veto balance, acceptance condition check |

### Forecasting & Estimation

| Algorithm | File | Notes |
|---|---|---|
| Grey Prediction GM(1,1) | `assets/code/matlab/grey_prediction.m` | Data prechecks (smoothness ratio, level ratio), model grade A/B/C/D |
| Kalman Filter | `assets/code/matlab/kalman_filter.m` | Configurable A/H/Q/R matrices, innovation diagnostics, filtered + predicted output |

### Optimization & Search

| Algorithm | File | Notes |
|---|---|---|
| Linear Programming | `assets/code/matlab/linear_programming.m` | Dual variable output (shadow prices), status interpretation, max/min support |
| Integer Programming | `assets/code/matlab/integer_programming.m` | MIP gap computation, optimal vs feasible distinction, 0-1 variable ready |
| Genetic Algorithm | `assets/code/matlab/genetic_algorithm.m` | Convergence history tracking, smart defaults, error handling |
| Particle Swarm | `assets/code/matlab/particle_swarm.m` | Iteration history, adaptive swarm size, convergence diagnosis |
| Simulated Annealing | `assets/code/matlab/simulated_annealing.m` | Temperature history, reannealing support, probabilistic escape |

### Uncertainty & Risk

| Algorithm | File | Notes |
|---|---|---|
| Monte Carlo Simulation | `assets/code/matlab/monte_carlo_simulation.m` | Parallel support, quantile reporting, SE estimation |
| Bootstrap CI | `assets/code/matlab/bootstrap_ci.m` | Percentile intervals, bias estimation, any statistic |

### Clustering

| Algorithm | File | Notes |
|---|---|---|
| DBSCAN | `assets/code/matlab/dbscan.m` | Density-based, arbitrary shapes, noise detection, k-distance guide |

### Network & Graph

| Algorithm | File | Notes |
|---|---|---|
| Dijkstra | `assets/code/matlab/dijkstra.m` | Single-source and all-pairs modes, path reconstruction via predecessors |

---

## Python Templates (Auxiliary)

### Initial Curated Template Set

- Linear programming -> `assets/code/python/linear_programming.py`
- Integer programming -> `assets/code/python/integer_programming.py`
- TOPSIS -> `assets/code/python/topsis.py`
- Entropy weight -> `assets/code/python/entropy_weight.py`
- Grey prediction -> `assets/code/python/grey_prediction.py`
- ARIMA forecast -> `assets/code/python/arima_forecast.py`
- Genetic algorithm -> `assets/code/python/genetic_algorithm.py`
- Particle swarm -> `assets/code/python/particle_swarm.py`
- PCA + SVM -> `assets/code/python/pca_svm.py`

### Combination-Model Anchors

These are not all fully productized local hybrids yet, but they already have the closest anchor templates:

- AHP + Entropy Weight -> `assets/code/python/ahp_entropy_weight.py`
- TOPSIS + Grey Relation -> `assets/code/python/topsis_grey_relation.py`
- DEA + TOPSIS -> `assets/code/python/dea_topsis.py`
- GM(1,1) + Markov -> `assets/code/python/gm11_markov.py`
- ARIMA + LSTM -> start from `assets/code/python/arima_forecast.py`
- SVM + PSO -> `assets/code/python/svm_pso.py`
- GA + SA -> `assets/code/python/ga_sa.py`
- PSO + Tabu Search -> start from `assets/code/python/particle_swarm.py`
- MOPSO -> start from `assets/code/python/particle_swarm.py`

---

## What to Edit for a New Problem

For each template, the typical customization points are:
1. **Objective function** — replace the placeholder with your problem-specific target
2. **Bounds and constraints** — encode your problem's feasible set
3. **Data preprocessing** — normalize, handle missing values, encode categoricals
4. **Parameter tuning** — adjust population size, epsilon, confidence level, etc.
5. **Output interpretation** — map results back to your problem domain
