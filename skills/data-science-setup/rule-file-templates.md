> Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

# Rule File Templates — Data Science Setup

## data-schema

```markdown
# Data Schema

Document one row per table/dataset. Claude reads this to answer questions about columns, units, and joins without guessing.

| Dataset | Location | Grain | Key columns | Notes |
|---|---|---|---|---|
| example | data/raw/example.parquet | one row per user-day | user_id, date | PII — do not ship externally |

## Column semantics
- `user_id` — stable across time; never re-used.
- `date` — UTC, ISO 8601.
- (extend as the project grows)

## Data lineage
- `data/raw/` — immutable source data. Never modified in place.
- `data/interim/` — cleaned, joined, not yet feature-engineered.
- `data/processed/` — model-ready features. Regenerable from raw + code.
```

## evaluation-protocol

```markdown
# Evaluation Protocol

## Metrics
- Primary: [fill in — e.g. AUC-ROC, RMSE, F1]
- Secondary / diagnostic: [fill in]

## Splits
- Train / validation / test split strategy: [time-based | random | group-based]
- Seed: fixed (see CLAUDE.md).
- Leakage checks: list any columns that must be excluded from features.

## Baselines
- Always report a trivial baseline (mean/mode/last-value) alongside any model.
- A new model is only considered better if it beats the baseline on the primary metric AND does not regress any secondary metric by more than [threshold].

## Reporting
- Log metrics to [Q4 tracker] under a named experiment.
- Include a confusion matrix / residual plot for every reported run.
- Save the trained model artifact with a hash of the training data and code commit.
```
