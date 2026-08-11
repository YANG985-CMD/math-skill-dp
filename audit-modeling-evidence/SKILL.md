---
name: audit-modeling-evidence
description: Audit data integrity, experiment reproducibility, claim-to-evidence tracing, and conclusion validity for mathematical modeling projects. Use after $math-skill-dp has produced results. Checks datasets, candidate validation, evidence bundles, and cross-file consistency. Do NOT use for initial modeling or figure creation.
---

# Audit Modeling Evidence

Verify that every claim in a modeling project is traceable to data, code, results, or verified references. Catch fabricated numbers, missing evidence, and inconsistent claims before they reach the paper.

## When to Use

- After `$math-skill-dp` has produced initial results and you need to verify them
- Before freezing canonical results for the paper
- When the claim-evidence ledger shows unverified claims
- When reviewing a teammate's modeling output

## Operating Workflow

1. Identify the project directory with a completed `audit/project-state.json`.
2. Run the dataset audit if data files are present:

       python scripts/audit_dataset.py INPUT.csv --target LABEL --time TIME --out-dir PROJECT_DIR/audit/dataset

3. Run the candidate evidence audit:

       python scripts/audit_candidate_evidence.py PROJECT_DIR/audit/candidate-validation.json --root PROJECT_DIR

4. Run the evidence bundle audit:

       python scripts/init_evidence_bundle.py PROJECT_DIR
       python scripts/audit_modeling_project.py PROJECT_DIR

5. For decision-trace problems, audit the backtracking trail:

       python scripts/audit_decision_trace.py PROJECT_DIR/audit/decision-trace.json --root PROJECT_DIR --out PROJECT_DIR/audit/decision-trace-audit.json

6. Review the generated `audit/latest-audit.md` for issues.
7. Fix all `error` and `warning` severity issues before delivery.

## Evidence Gates Checked

| Gate | What It Verifies | Tool |
|------|-----------------|------|
| Intake | Data sources, provenance, missingness, leakage | `audit_dataset.py` |
| Method | Baseline executed, candidate comparison, feasibility | `audit_modeling_project.py` (method gate) |
| Computation | Code actually ran, env recorded, outputs exist | `audit_modeling_project.py` (computation gate) |
| Evidence | Frozen results, baseline comparison, robustness | `audit_modeling_project.py` (evidence gate) |
| Candidate | Reproducibility, sensitivity, structural validity | `audit_candidate_evidence.py` |

## Non-Negotiable Rules

- Never accept a "passed" status without checking the actual evidence files exist.
- A claim without an artifact path is a failing claim.
- Data audit automated flags are screening evidence, not automatic deletion rules.
- Re-run the audit after ANY upstream change (data, method, parameters).
- A failed gate blocks all downstream gates — fix in order.
