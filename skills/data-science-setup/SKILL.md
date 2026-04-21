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

If the delimited block already exists from a previous run (either the attributed form above or the legacy unattributed `<!-- onboarding-agent:start -->` form), replace only the content between the markers; leave the rest of the file untouched. Upgrade the opening marker to the attributed form while you are there — `/upgrade-setup` depends on it for detection.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 4)
- `stack-scaffolds.md` — `pyproject.toml`, `uv add` commands, `.claude/settings.json` permissions, directory scaffold (Step 4)
- `gitignore-block.md` — the `.gitignore` block (Step 4)
- `notebook-hygiene.md` — `.pre-commit-config.yaml` for nbstripout + nbqa (Step 4)

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
- Data schema and column semantics: `.claude/rules/data-schema.md`
- Evaluation protocol and metrics: `.claude/rules/evaluation-protocol.md`
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

Keep this file short (≤ 30 lines). Details belong in `.claude/rules/*.md`.

### .claude/rules/data-schema.md

Read `rule-file-templates.md` and write its `data-schema` section to `.claude/rules/data-schema.md`. Skip the write if the file already exists.

### .claude/rules/evaluation-protocol.md

Read `rule-file-templates.md` and write its `evaluation-protocol` section to `.claude/rules/evaluation-protocol.md`. Skip the write if the file already exists.

### pyproject.toml and uv add commands (only if Q1 includes Python and `uv_available: true`)

Read `stack-scaffolds.md`. Emit its `pyproject.toml` section. Print the install commands from the "uv add commands by answer" section, selecting bullets that match Q2 / Q3 / Q4 / Q6. Never execute `uv add` without explicit user consent. If `uv_available: false`, print the commands as a manual checklist.

### .claude/settings.json

Read `stack-scaffolds.md`. Create or extend `.claude/settings.json` using the "base permissions" section, then merge in the adaptations from "per-answer adaptations" that match Q1 / Q2 / Q4. If the file already exists, merge into its `permissions.allow` list (dedupe), do not overwrite.

### Directory scaffold (only if Q5 = yes)

Read `stack-scaffolds.md` and create the directories and `data/README.md` from its "Directory scaffold" section.

### .gitignore

Read `gitignore-block.md` and append its block to the user's `.gitignore` (delimited markers; replace only the content between them if already present).

### Notebook hygiene (only if Q6 = yes)

Read `notebook-hygiene.md` and emit its `.pre-commit-config.yaml` section plus the `pre-commit install` instruction.

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
  .claude/rules/data-schema.md                 — datasets, columns, lineage
  .claude/rules/evaluation-protocol.md         — metrics, splits, baselines, reporting
  pyproject.toml                               — [created | skipped — uv missing | skipped — non-Python stack]
  .claude/settings.json                        — tool permissions for [stack summary]
  .gitignore                                   — raw data, notebook checkpoints, experiment artifacts
  data/{raw,interim,processed}/                — [created | skipped per user choice]
  .pre-commit-config.yaml                      — [created | skipped per user choice]
  .claude/onboarding-meta.json                 — setup marker for /upgrade-setup

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
  2. Fill in `.claude/rules/data-schema.md` with your real datasets.
  3. Fill in `.claude/rules/evaluation-protocol.md` with your primary metric.
  4. Start a new Claude session: "Explore data/raw/<file> and propose a feature-engineering plan."
  5. [If Graphify installed] Try: /graphify query "which notebooks use <feature>?"
```
