---
name: data-science-setup
description: Set up Claude for data science and ML engineering — configures notebook workflow, experiment tracking, reproducibility conventions, and data layout so Claude supports you from exploration to productive modeling.
---

# Data Science / ML Setup

This skill configures Claude for exploratory and productive data science / ML work. It is the right choice when your project centers on notebooks, models, datasets, and experiments — not general application code (use `coding-setup` for that) and not literature research (use `research-setup` for that).

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

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
- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)
- `skills/_shared/offer-superpowers.md` — canonical Superpowers opt-in (Step 1)
- `skills/_shared/offer-graphify.md` — canonical Graphify opt-in (Step 6)

## Step 1: Install Dependencies

Read `skills/_shared/offer-superpowers.md` and run it with `skill_slug: data-science-setup`, `mandatory: false`, `capability_line: "A free Claude Code skills library (94,000+ users). Useful for planning multi-step experiments and structuring model-training pipelines."` The helper asks the user, delegates to `skills/_shared/installation-protocol.md` on `yes`, and sets `superpowers_installed`, `superpowers_scope`, `superpowers_method`.

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

## Step 4: Offer Project-Local Subagent

Read `skills/_shared/emit-subagent.md` and follow it with these inputs:

- `slug`: `notebook-auditor`
- `purpose_blurb`: "Audit a notebook or training script for reproducibility — seed setting, split integrity, leakage, baseline logging."
- `frontmatter_description`: "Use to review a notebook or training script for reproducibility — seed setting, train/val/test split integrity, data leakage, baseline logging, metric correctness. Dispatch when the user asks to review a notebook, check an experiment, audit reproducibility, or 'verify the split'."
- `tools_list`: `Read, Grep, Glob, Bash`
- `rules_files`: `.claude/rules/evaluation-protocol.md, .claude/rules/data-schema.md`
- `body_markdown`:

  ```
  You are the Notebook Auditor. You audit a notebook or training script for reproducibility and correctness against the project's evaluation protocol and data schema.

  ## Procedure
  1. Identify the target notebook/script.
  2. Read evaluation-protocol.md (metrics, splits, baselines) and data-schema.md (datasets, columns, lineage).
  3. Audit for: missing seed setting, split leakage (test in train, temporal leakage), metric mismatch with protocol, missing baseline, hardcoded paths that break re-runs, missing environment pinning.
  4. Return a structured verdict: target file, findings with cell/line reference, severity, and recommended fix.

  ## Rules
  - Do not re-run the notebook. Read-only audit unless the caller explicitly requests execution.
  - If a rules file is missing, audit against standard ML reproducibility defaults and say so in the header.
  ```

Record the emit outcome for use in the completion summary (Step 9). If `emit_subagent: true`, add `"notebook-auditor"` to the list passed to `skills/_shared/write-meta.md` in Step 7 as `subagents_installed`.

## Step 5: Generate Artifacts

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

Read `gitignore-block.md` for the data-science-specific lines and the delimited-marker shape. Inside the marker block, inline the Python patterns from `skills/_shared/gitignore-python.md` and the shared common patterns from `skills/_shared/gitignore-common.md` (single source of truth for Python / OS / env / Claude-local lines). Append the fully assembled block to the user's `.gitignore`; if the marker block already exists, replace only the content between the markers.

### Notebook hygiene (only if Q6 = yes)

Read `notebook-hygiene.md` and emit its `.pre-commit-config.yaml` section plus the `pre-commit install` instruction.

### Optional: nbstripout PostToolUse hook

Only ask if Q6 (notebook hygiene) = yes AND Q2 (editor) ≠ "neither Jupyter nor marimo". Otherwise skip.

Ask ONCE (adapt to detected language):

> "Install the nbstripout-on-save hook? After every Edit/Write to a `.ipynb` file, Claude Code runs `nbstripout` in place to remove cell outputs. Keeps diffs clean without relying on the pre-commit hook firing. (yes / no)"

Default on empty input: `yes`.

On `no`: set `ds_hook_emitted: false` and skip.

On `yes`:

1. Write the strip script body:

   ```bash
   #!/usr/bin/env bash
   # Generated by claude-onboarding-agent (skill: data-science-setup)
   # Purpose: strip Jupyter cell outputs on save so diffs stay clean.
   # Safe to delete — Claude Code will continue without the hook.

   set -u

   INPUT=$(cat)
   FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)
   [ -z "$FILE" ] && exit 0

   case "$FILE" in
     *.ipynb) : ;;
     *) exit 0 ;;
   esac

   if ! command -v nbstripout >/dev/null 2>&1; then
     jq -cn --arg ctx "Edited a notebook ($FILE) but \`nbstripout\` is not installed. Run \`uv add --dev nbstripout\` to activate the on-save strip, or strip manually before committing." \
       '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
     exit 0
   fi

   nbstripout "$FILE" >/dev/null 2>&1 || true
   exit 0
   ```

2. Set the hook spec (the helper writes `"_plugin": "claude-onboarding-agent"` and `"_skill": "data-science-setup"` into the emitted entry):

   ```
   hook_entries = [
     {
       event: "PostToolUse",
       matcher: "Edit|Write",
       command: "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/data-nbstripout.sh\"",
       script_name: "data-nbstripout.sh",
       script_source: <the bash block above>
     }
   ]
   skill_slug = "data-science-setup"
   ```

3. Read `skills/_shared/emit-hook.md` and follow every step H1–H7.

4. Capture the status variables.

## Step 6: Optional Graphify Integration

Read `skills/_shared/offer-graphify.md` and run it with:

- `host_setup_slug: "data-science"`
- `host_skill_slug: "data-science-setup"`
- `run_initial_build: true`
- `install_git_hook: true`
- `corpus_blurb: "your project (Python code via tree-sitter for 25 languages, Markdown docs, Jupyter notebooks' text content, PDFs of papers, diagrams, images). Useful on larger ML repos with many experiments and notes"`

The helper owns the opt-in prompt and the three-way branch (yes / no / later),
delegating to `skills/_shared/graphify-install.md`. Record the `graphify_*`
variables it produces for use in Step 9.

## Step 7: Write Upgrade Metadata

Set `setup_slug: data-science`, `skill_slug: data-science-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. If Step 4 emitted the `notebook-auditor` subagent, set `subagents_installed: ["notebook-auditor"]`; otherwise leave it unset. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`. If Step 6 installed Graphify, `skills_used` will include both `data-science-setup` and `graphify-setup`.

## Step 8: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: data-science`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: data-science`
   - `skill_slug: data-science-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs to mention in the completion summary.

## Step 9: Completion Summary

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
  .claude/agents/notebook-auditor.md           — project-local subagent (auto-invoked) [only on yes path; if skipped existing: .claude/agents/notebook-auditor.md (already existed — skipped; re-run /checkup --rebuild to regenerate); if no/later: Subagent notebook-auditor not installed — re-run /data-science-setup to add it later.]
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

Hooks:
  [✓ nbstripout PostToolUse hook written to .claude/settings.json + .claude/hooks/data-nbstripout.sh
   | — skipped per user
   | ⚠ settings.json is corrupt — entries printed above for manual paste
   | — not offered (notebook hygiene not enabled)]

Next steps:
  1. If Python: run the `uv add` commands printed above in your project root.
  2. Fill in `.claude/rules/data-schema.md` with your real datasets.
  3. Fill in `.claude/rules/evaluation-protocol.md` with your primary metric.
  4. Start a new Claude session: "Explore data/raw/<file> and propose a feature-engineering plan."
  5. [If Graphify installed] Try: /graphify query "which notebooks use <feature>?"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
