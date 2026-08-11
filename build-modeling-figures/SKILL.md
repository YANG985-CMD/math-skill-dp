---
name: build-modeling-figures
description: Generate and audit publication-grade quantitative figures and code-native modeling diagrams for mathematical modeling papers. Use for chart selection, multi-panel layouts, scientific plotting, vector export, grayscale checks, and figure QA. Use after $math-skill-dp has produced results; do NOT use for initial modeling.
---

# Build Modeling Figures

Turn modeling results into publication-grade figures. Every figure starts with a one-sentence conclusion and is generated from traceable data with programmatic QA.

## When to Use

- After canonical results are frozen and you need paper-ready figures
- When the figure contract in `planning/figure-contract.json` is ready
- When you need to audit existing figures for publication compliance
- When selecting chart types for specific data structures

## Figure Design Process

1. **Answer the core question first**: "What is the ONE thing this figure must prove?"
2. **Select the chart archetype** based on data structure:
   - Comparison with uncertainty → bar chart with error bars
   - Time series forecast → observed + predicted + confidence band
   - Optimization convergence → objective over iterations + constraint violations
   - Group distributions → box plot + raw data points
   - Trade-off → Pareto front + feasible/infeasible markers
   - Sensitivity → heatmap with explicit factor labels
3. **Define the figure contract** using `assets/templates/figure-contract-template.json`.
4. **Generate the figure** using `assets/code/python/modeling_plotkit.py` or MATLAB native plotting.
5. **Run programmatic QA** with `audit_figure()`.
6. **Export** SVG + PDF + 300dpi PNG + grayscale preview.
7. **Visually inspect** the rendered output at final size.

## Recommended PlotKit Functions

| Data Story | Function |
|------------|----------|
| Compare methods with uncertainty | `plot_method_comparison(ax, labels, values, errors=..., baseline=..., highlight=...)` |
| Show forecast with confidence | `plot_forecast(ax, x, observed, predicted, lower=..., upper=..., split_index=...)` |
| Track optimization progress | `plot_convergence(ax, iters, obj, violation=..., baseline=...)` |
| Display group distributions | `plot_group_distribution(ax, labels, groups, ylabel=...)` |
| Visualize trade-offs | `plot_pareto(ax, x, y, feasible=..., selected=...)` |
| Show parameter sensitivity | `plot_sensitivity_heatmap(ax, matrix, xlabels, ylabels, ...)` |

## Figure QA Checklist

Run `scripts/audit_figure_bundle.py` for programmatic checks. Then visually verify:

- [ ] All axes have labels with units
- [ ] Legend is present and non-redundant
- [ ] Text is readable at final size (≥ 6.5pt)
- [ ] Colors are distinguishable in grayscale
- [ ] Baseline or reference is marked when applicable
- [ ] Uncertainty or statistics are shown
- [ ] No AI-generated imagery is used as empirical evidence
- [ ] Vector output renders correctly

## Non-Negotiable Rules

- Every figure must have exactly ONE primary conclusion.
- Quantitative figures must be generated from traceable data and code.
- Never use AI-generated imagery as empirical evidence.
- SVG/PDF masters + 300dpi PNG + grayscale check required for delivery.
- Missing axis labels, unreadable text, or outside-canvas elements = failure.
