---
name: data-science-setup
description: Set up Claude for data science and ML engineering — configures notebook workflow, experiment tracking, reproducibility conventions, and data layout so Claude supports you from exploration to productive modeling.
---

# Data Science / ML Setup

This skill configures Claude for exploratory and productive data science / ML work. It is the right choice when your project centers on notebooks, models, datasets, and experiments — not general application code (use `coding-setup` for that) and not literature research (use `research-setup` for that).

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout. All generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if `CLAUDE.md` already exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=data-science skill=data-science-setup section=claude-md -->
## Claude Onboarding Agent — Data Science Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form while you are there — `/upgrade` depends on it for detection.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Useful for planning multi-step experiments and structuring model-training pipelines." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Verify Python Tooling

Run `uv --version` (via Bash).

- If the command succeeds: set `uv_available: true` and continue.
- If it fails: set `uv_available: false` and print ONCE:

  > "⚠ `uv` is not installed. This skill strongly recommends `uv` as the Python package manager for data-science projects (reproducible lockfiles, fast installs, no global pollution). Install it from https://docs.astral.sh/uv/getting-started/installation/ and re-run this skill when ready. Setup will continue, but `pyproject.toml` and `uv add` steps will be emitted as instructions only — nothing will be executed on your machine."

Never try to install `uv` automatically, and never fall back to `pip`, `poetry`, or `conda`.

## Step 3: Context Questions

Ask these questions ONE AT A TIME. Wait for each answer before asking the next.

1. "Which language / stack is this project built on?
   A) Python + uv (default, recommended)
   B) R
   C) Julia
   D) Mixed (Python + one of the above)"

2. "Which notebook tool do you use?
   A) Jupyter (classic / JupyterLab)
   B) marimo (reactive, git-friendly)
   C) VS Code notebooks
   D) None / plain scripts only"

3. "Which deep-learning / heavy ML framework, if any?
   A) PyTorch
   B) JAX
   C) TensorFlow / Keras
   D) None — classical ML only (scikit-learn, XGBoost, etc.)"

4. "Which experiment tracker do you want Claude to be aware of?
   A) MLflow
   B) Weights & Biases (wandb)
   C) DVC (data + experiment versioning)
   D) None / not yet"

5. "Should I scaffold the standard `data/raw/`, `data/interim/`, `data/processed/` layout and add raw-data ignore rules? (yes / no)"

6. "Should Claude enforce notebook hygiene — strip outputs on commit, run `nbqa` for lint/format? (yes / no)"

## Step 4: Generate Artifacts

Generate the following files. For each, if the file already exists, extend rather than overwrite (see "Existing CLAUDE.md" rule at the top; apply the same delimited-section principle to `.gitignore` by appending a new `# onboarding-agent: data-science` block).

### CLAUDE.md (≤ 30 lines — pointers only)

```markdown
# Claude Instructions — Data Science / ML

## Project Context
Stack: [Q1 answer]. Notebooks: [Q2 answer]. ML framework: [Q3 answer]. Experiment tracking: [Q4 answer].

## Key Pointers
- Data schema and column semantics: `claude_instructions/data-schema.md`
- Evaluation protocol and metrics: `claude_instructions/evaluation-protocol.md`
- Model cards live under `models/<name>/MODEL_CARD.md`

## Workflow Rules
- Reproducibility: set seeds, pin `pyproject.toml` (uv.lock), record dataset hash per experiment.
- Data layout: read from `data/raw/` (read-only), write intermediates to `data/interim/`, final features to `data/processed/`.
- Never commit raw data, secrets, or `.env` files.
- Notebooks: strip outputs before commit; run `nbqa ruff` / `nbqa black` for lint/format.
- Experiments: log params, metrics, and artifacts to [Q4 tracker]; link runs from the PR description.

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. Use `superpowers:brainstorming` before non-trivial modeling changes and `superpowers:writing-plans` for multi-step experiments.
```

Keep this file short (≤ 30 lines). Details belong in `claude_instructions/*.md`.

### claude_instructions/data-schema.md

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

### claude_instructions/evaluation-protocol.md

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

### pyproject.toml (only if Q1 includes Python AND `uv_available: true`)

Emit a minimal scaffold and instruct the user to run the install commands. Do NOT run `uv add` automatically without explicit user consent.

```toml
[project]
name = "your-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[tool.uv]
dev-dependencies = []
```

Then print the recommended install commands based on answers:

- Always: `uv add pandas polars numpy pyarrow scikit-learn`
- If Q2 = Jupyter: `uv add jupyterlab ipykernel`
- If Q2 = marimo: `uv add marimo`
- If Q3 = PyTorch: `uv add torch` (remind the user to check https://pytorch.org for the correct CUDA build)
- If Q3 = JAX: `uv add "jax[cpu]"` (or `jax[cuda12]` with extra index URL — link to JAX install docs)
- If Q3 = TensorFlow: `uv add tensorflow`
- If Q4 = MLflow: `uv add mlflow`
- If Q4 = Weights & Biases: `uv add wandb`
- If Q4 = DVC: `uv add dvc`
- If Q6 = yes (notebook hygiene): `uv add --dev nbqa ruff black nbstripout pre-commit`

If `uv_available: false`, print these as a manual checklist instead of executing them.

### .claude/settings.json (Python stacks)

Create or extend `.claude/settings.json` with stack-appropriate permissions:

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(uv *)",
      "Bash(python *)",
      "Bash(pytest *)",
      "Bash(jupyter *)",
      "Bash(nbqa *)",
      "Bash(nbstripout *)",
      "Bash(pre-commit *)"
    ]
  }
}
```

Adapt based on answers:
- Q2 = marimo → add `"Bash(marimo *)"`
- Q4 = MLflow → add `"Bash(mlflow *)"`
- Q4 = Weights & Biases → add `"Bash(wandb *)"`
- Q4 = DVC → add `"Bash(dvc *)"`
- Q1 = R → add `"Bash(Rscript *)"`, `"Bash(R *)"` instead of the uv/python entries
- Q1 = Julia → add `"Bash(julia *)"` instead

If an existing `settings.json` exists, merge into its `permissions.allow` list (dedupe) rather than overwriting.

### Directory scaffold (only if Q5 = yes)

Create:

```
data/
  raw/.gitkeep
  interim/.gitkeep
  processed/.gitkeep
models/.gitkeep
notebooks/.gitkeep
```

Add a `data/README.md` explaining the three-folder convention (raw = immutable, interim = cleaned, processed = model-ready).

### .gitignore

Append a delimited block at the end. If the marker block already exists, replace it.

```gitignore
# onboarding-agent: data-science — start
# Raw and processed data (only if Q5 = yes)
data/raw/*
!data/raw/.gitkeep
data/interim/*
!data/interim/.gitkeep
data/processed/*
!data/processed/.gitkeep

# Notebook checkpoints and local state
.ipynb_checkpoints/
*.nbconvert.ipynb
.jupyter/

# Experiment artifacts
mlruns/
wandb/
.dvc/cache/
.dvc/tmp/

# Model artifacts (re-generable — keep model cards, not weights)
models/**/*.pt
models/**/*.bin
models/**/*.onnx
models/**/*.joblib
models/**/*.pkl

# Python
__pycache__/
.venv/
*.pyc
dist/
.env

# Claude local settings
.claude/settings.local.json
# onboarding-agent: data-science — end
```

### Notebook hygiene (only if Q6 = yes)

Emit a `.pre-commit-config.yaml` scaffold and instruct the user to run `pre-commit install` once:

```yaml
repos:
  - repo: https://github.com/kynan/nbstripout
    rev: 0.7.1
    hooks:
      - id: nbstripout
  - repo: https://github.com/nbQA-dev/nbQA
    rev: 1.8.5
    hooks:
      - id: nbqa-ruff
      - id: nbqa-black
```

If `pre-commit` is not installed, print: "Run `uv add --dev pre-commit && uv run pre-commit install` to activate the hooks."

## Step 5: Optional Graphify Integration

Ask ONCE (adapt to detected language):

> "Install Graphify knowledge-graph integration now?
>
> Graphify indexes your project (Python code via tree-sitter for 25 languages, Markdown docs, Jupyter notebooks' text content, PDFs of papers, diagrams, images) into a local graph, registers a `/graphify` slash command, and adds a PreToolUse hook that consults the graph BEFORE Claude runs Grep / Glob / Read. Useful on larger ML repos with many experiments and notes. See https://github.com/safishamsi/graphify.
>
> (yes / no / later)"

- **yes** → set `host_setup_slug: "data-science"`, `host_skill_slug: "data-science-setup"`, `run_initial_build: true`, `install_git_hook: true`. Read `skills/_shared/graphify-install.md` and follow steps G1–G9 in order. The protocol writes the attributed CLAUDE.md section with `setup=data-science skill=graphify-setup section=graphify`.
- **no** → set `graphify_installed: false` and skip to Step 6.
- **later** → invoke `skills/_shared/graphify-install.md` in "later" mode: skip G1–G7 and write only the short deferred pointer block. Set `graphify_installed: false`, `graphify_deferred: true`.

## Step 6: Write Upgrade Metadata

Set `setup_slug: data-science`, `skill_slug: data-science-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 5 installed Graphify, `skills_used` will include both `data-science-setup` and `graphify-setup`.

## Step 7: Completion Summary

```
✓ Data Science / ML setup complete!

Files created / updated:
  CLAUDE.md                                    — pointers + workflow rules (delimited section)
  claude_instructions/data-schema.md           — datasets, columns, lineage
  claude_instructions/evaluation-protocol.md   — metrics, splits, baselines, reporting
  pyproject.toml                               — [created | skipped — uv missing | skipped — non-Python stack]
  .claude/settings.json                        — tool permissions for [stack summary]
  .gitignore                                   — raw data, notebook checkpoints, experiment artifacts
  data/{raw,interim,processed}/                — [created | skipped per user choice]
  .pre-commit-config.yaml                      — [created | skipped per user choice]
  .claude/onboarding-meta.json                 — setup marker for /upgrade

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Environment:
  [✓ uv detected]
  [⚠ uv missing — install from https://docs.astral.sh/uv/getting-started/installation/ before running the listed uv commands]

Graphify (knowledge graph):
  [✓ installed via <installer>, /graphify + PreToolUse hook registered | ⚠ installed but hook not verified — run /graphify in a new session | — skipped: <reason> | — deferred: run /graphify-setup when ready | — not offered]

Next steps:
  1. If Python: run the `uv add` commands printed above in your project root.
  2. Fill in `claude_instructions/data-schema.md` with your real datasets.
  3. Fill in `claude_instructions/evaluation-protocol.md` with your primary metric.
  4. Start a new Claude session: "Explore data/raw/<file> and propose a feature-engineering plan."
  5. [If Graphify installed] Try: /graphify query "which notebooks use <feature>?"
```
