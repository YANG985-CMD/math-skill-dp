---
name: deliver-cumcm-paper
description: Generate, compile, audit, and deliver CUMCM-format LaTeX papers for Chinese mathematical modeling competitions. Use for paper building, LaTeX compilation, format preflight, and submission-ready PDF production. Use only after $math-skill-dp has frozen canonical results and figures are ready.
---

# Deliver CUMCM Paper

Produce a submission-ready CUMCM competition paper from frozen results, audited figures, and verified claims. Build independently authored LaTeX, compile to PDF, and pass format preflight checks.

## When to Use

- After all canonical results are frozen in `results/frozen-results.json`
- After all figures have passed QA
- When the manuscript contract in `paper/manuscript-contract.json` is approved
- Before final submission — for format compliance checking

## Operating Workflow

1. **Verify prerequisites**: frozen results exist, figures pass QA, claims are verified.
2. **Generate frozen-result tables**:

       python scripts/render_frozen_results.py results/frozen-results.json --root PROJECT_DIR --out paper/generated/frozen-results.md

3. **Copy and customize the LaTeX template**:

       Copy-Item assets/latex/cumcm-2026/paper.tex PROJECT_DIR/paper.tex

4. **Build the PDF**:

       python scripts/build_cumcm_latex.py PROJECT_DIR/paper.tex --output-dir PROJECT_DIR/build/cumcm

5. **Run format preflight**:

       python scripts/audit_cumcm_latex.py PROJECT_DIR/paper.tex --pdf PROJECT_DIR/build/cumcm/paper.pdf --support-archive PROJECT_DIR/support.zip --body-pages 24 --json-out PROJECT_DIR/build/cumcm/audit.json --strict

6. **Perform visual review**: check every page of the PDF for formula rendering, figure placement, page breaks, and garbled characters.

## Directory Structure for Delivery

```
PROJECT_DIR/
├── paper.tex                    # Independently authored LaTeX source
├── build/cumcm/
│   ├── paper.pdf               # Compiled PDF
│   ├── audit.json              # Format audit results
│   └── build-manifest.json     # Build environment record
├── support.zip                 # Supporting materials
└── paper/
    ├── manuscript-contract.json
    ├── terminology-ledger.csv
    └── generated/
        └── frozen-results.md   # Auto-generated result tables
```

## CUMCM 2026 Format Requirements (Auto-Checked)

| Check | What It Verifies |
|-------|-----------------|
| Paper size | A4 |
| Margins | Standard CUMCM margins |
| Abstract order | Title → Abstract → Keywords → Body |
| Table of contents | Present and ordered |
| Anonymous fields | No author/school info in visible text |
| Cross-references | All \\ref{} targets exist |
| Placeholders | No TODO or XXX in final TeX |
| File size | PDF under reasonable limit |

## Non-Negotiable Rules

- Paper TeX must be independently authored — do not copy from community templates whose license is unknown.
- All numbers in the paper must come from `frozen-results.json`, not retyped.
- Figures must be included by reference to their audited paths.
- Recheck the CURRENT YEAR's official CUMCM notice before every formal submission.
- A failed format check must be fixed before delivery. Do not deliver with known audit failures.
- Perform a full page-by-page visual review of the final PDF.
