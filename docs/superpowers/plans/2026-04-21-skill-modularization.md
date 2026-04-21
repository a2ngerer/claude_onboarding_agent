# Skill Modularization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce `web-development-setup`, `academic-writing-setup`, and `data-science-setup` SKILL.md files below 300 lines by extracting bulk content (rule-file bodies, artifact skeletons, matrices, gitignore blocks) into sibling `.md` files in each skill directory. Lock the 300-line threshold, the canonical sibling-filename table, the extraction boundary, and the reference pattern into `CLAUDE.md`.

**Architecture:** Markdown-only refactor of existing SKILL.md files plus new sibling files in each skill directory. No executable code. SKILL.md files remain the entry prompts; siblings are read on-demand at the step that needs them. Verification is grep- and `wc -l`-based.

**Tech Stack:** Markdown, Claude Code skill framework.

**Spec:** `docs/superpowers/specs/2026-04-21-skill-modularization-design.md` — read it first. Every task below references decisions made there.

---

## Conventions for this plan

- Commit messages follow the existing repo style (`feat(scope):`, `refactor(scope):`, `docs(scope):`, `chore(scope):`). One commit per task.
- "Test" for a markdown refactor = `grep` / `wc -l` before and after. "Failing test" = the old content still sits in SKILL.md. "Passing test" = SKILL.md is short and the content is now in a sibling.
- **Never** use `git commit --no-verify`. If a pre-commit hook fails, fix the underlying issue.
- Language for all committed artifacts: English (repo rule).
- Canonical sibling-filename table (used across every task):

  | Filename | Purpose |
  |---|---|
  | `rule-file-templates.md` | Ready-to-write bodies of `.claude/rules/<topic>.md` files the skill generates |
  | `gitignore-block.md` | The delimited `.gitignore` block plus `.env.example` (where applicable) |
  | `framework-defaults.md` | Framework/stack matrices |
  | `document-skeletons.md` | Artifact skeletons (e.g. `main.tex`, `pyproject.toml`) |
  | `stack-scaffolds.md` | Mixed per-stack scaffolds (pyproject + settings.json combinations) |

- Every sibling starts with a one-line consumer note:

  ```markdown
  > Consumed by <skill-name>/SKILL.md at Step <N>. Do not invoke directly.
  ```

- Every SKILL.md reference to a sibling uses the pattern `` Read `<filename>` `` so grep can verify coverage.

## File Structure

**Modified:**

- `CLAUDE.md` (repo root) — new "SKILL.md Modularization" subsection under "Skill Authoring Rules"
- `skills/web-development-setup/SKILL.md` — shrunk to ≤ 260 lines
- `skills/academic-writing-setup/SKILL.md` — shrunk to ≤ 240 lines
- `skills/data-science-setup/SKILL.md` — shrunk to ≤ 220 lines

**New (per skill directory):**

- `skills/web-development-setup/rule-file-templates.md`
- `skills/web-development-setup/framework-defaults.md`
- `skills/web-development-setup/gitignore-block.md`
- `skills/web-development-setup/document-skeletons.md`
- `skills/academic-writing-setup/rule-file-templates.md`
- `skills/academic-writing-setup/document-skeletons.md`
- `skills/academic-writing-setup/gitignore-block.md`
- `skills/academic-writing-setup/optional-integrations.md`
- `skills/data-science-setup/rule-file-templates.md`
- `skills/data-science-setup/stack-scaffolds.md`
- `skills/data-science-setup/gitignore-block.md`
- `skills/data-science-setup/notebook-hygiene.md`

**Untouched:** `.claude-plugin/plugin.json` (siblings are runtime-read by SKILL.md, not registered in the manifest). Verified by `git diff` in the verification task.

---

## Task 1 — Authoring Docs in CLAUDE.md

**Files:**

- Modify: `CLAUDE.md` (repo root)

- [ ] **Step 1: Verify the "Skill Authoring Rules" section exists**

  Run: `grep -n "Skill Authoring Rules" CLAUDE.md`
  Expected: returns a line number.

- [ ] **Step 2: Append a "SKILL.md Modularization" subsection under "Skill Authoring Rules"**

  Use the Edit tool. Find the last bullet of the existing "Skill Authoring Rules" section (currently: `- Never silently overwrite an existing CLAUDE.md — always extend with a new delimited section`). Insert the following block directly after that bullet, separated by a blank line:

  ```markdown

  ## SKILL.md Modularization

  A SKILL.md file requires modularization when it exceeds **300 lines**. Files in the 200–300 band are audited on edit but not forced. Files under 200 lines stay inline.

  **Extraction boundary — stays in SKILL.md:**
  - YAML front matter, intro, placement advice
  - Language / handoff-context / existing-CLAUDE.md handling
  - Step ordering, one-line step descriptions, context questions
  - Decision branches and short environment probes
  - Installation-protocol / graphify-install / write-meta invocations
  - Completion-summary template

  **Extraction boundary — moves to sibling files:**
  - Rule-file content bodies (what the skill writes into `.claude/rules/<topic>.md`)
  - Gitignore blocks and `.env.example` scaffolds
  - Framework/stack lookup matrices longer than ~10 rows
  - Artifact skeletons (`main.tex`, `pyproject.toml`, `package.json`, `.pre-commit-config.yaml`)
  - Per-framework install-command lists
  - Per-stack `.claude/settings.json` bodies longer than ~15 lines
  - Provider-specific instructions relevant only under one question's answer

  Blocks shorter than ~15 lines and relevant on every path through the skill stay inline.

  ### Canonical Sibling Filenames

  Use these names across skills wherever the content domain fits. A new name is allowed only when none of these applies and it must describe a content domain (not a step or phase).

  | Filename | Purpose |
  |---|---|
  | `rule-file-templates.md` | Ready-to-write bodies of `.claude/rules/<topic>.md` files |
  | `gitignore-block.md` | The delimited `.gitignore` block plus `.env.example` |
  | `framework-defaults.md` | Framework/stack lookup matrices |
  | `document-skeletons.md` | Artifact skeletons (`main.tex`, `pyproject.toml`, etc.) |
  | `stack-scaffolds.md` | Mixed per-stack scaffolds (pyproject + settings.json combinations) |

  Siblings live in the same directory as `SKILL.md`, flat (no subdirectories). Two skills may each own a `rule-file-templates.md`; each is scoped to its own skill directory.

  ### Reference Pattern

  Near the top of SKILL.md (after the existing-CLAUDE.md block), add a `## Supporting Files` listing:

  ```markdown
  ## Supporting Files

  Read these on-demand at the step that invokes them. Do not read eagerly.

  - `rule-file-templates.md` — bodies of the .claude/rules/*.md files this skill generates
  - `gitignore-block.md` — the .gitignore block and .env.example scaffold
  ```

  At each step that needs a sibling, instruct Claude explicitly: `` Read `<filename>` and write the <artifact> section to <target> ``. Do not rely on a global table of contents.

  Every sibling opens with a one-line consumer note: `> Consumed by <skill>/SKILL.md at Step <N>. Do not invoke directly.`

  **Review checklist:** When editing a sibling, grep SKILL.md for its filename to confirm the reference still matches. When editing SKILL.md, scan the Supporting-Files block.
  ```

- [ ] **Step 3: Verify the section landed**

  Run: `grep -c "SKILL.md Modularization" CLAUDE.md`
  Expected: `1`.

  Run: `grep -c "rule-file-templates.md" CLAUDE.md`
  Expected: `2` (one in the canonical table, one in the reference-pattern example).

- [ ] **Step 4: Commit**

  ```bash
  git add CLAUDE.md
  git commit -m "docs(claude-md): add SKILL.md modularization threshold and sibling convention"
  ```

---

## Task 2 — Modularize `skills/web-development-setup/SKILL.md`

**Files:**

- Create: `skills/web-development-setup/rule-file-templates.md`
- Create: `skills/web-development-setup/framework-defaults.md`
- Create: `skills/web-development-setup/gitignore-block.md`
- Create: `skills/web-development-setup/document-skeletons.md`
- Modify: `skills/web-development-setup/SKILL.md`

- [ ] **Step 1: Baseline**

  Run: `wc -l skills/web-development-setup/SKILL.md`
  Expected: ~543 (pre-refactor).

  Record the pre-refactor distinctive-token counts for parity checks:

  ```bash
  grep -c "NEXT_PUBLIC_" skills/web-development-setup/SKILL.md
  grep -c "api-conventions" skills/web-development-setup/SKILL.md
  grep -c "component-structure" skills/web-development-setup/SKILL.md
  grep -c "env-vars" skills/web-development-setup/SKILL.md
  grep -c "# onboarding-agent: web-development" skills/web-development-setup/SKILL.md
  ```

  Write the counts down — the post-refactor total across SKILL.md + siblings must equal or exceed each.

- [ ] **Step 2: Create `rule-file-templates.md`**

  Use the Write tool to create `skills/web-development-setup/rule-file-templates.md` with the following structure. Copy the three markdown code blocks currently inside `### claude_instructions/api-conventions.md`, `### claude_instructions/component-structure.md`, and `### claude_instructions/env-vars.md` sections of the current SKILL.md, unchanged. Each becomes an H2 section:

  ```markdown
  > Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

  # Rule File Templates — Web Development Setup

  This file holds the ready-to-write bodies of the three `.claude/rules/*.md` files the skill generates. SKILL.md instructs Claude which section to emit based on Q1–Q7 answers.

  ## api-conventions

  <paste the exact markdown code block currently in SKILL.md under "### claude_instructions/api-conventions.md" — the whole fenced block including route layout, error shape, auth header, request validation, OpenAPI, and rate limiting sections>

  ## component-structure

  <paste the exact markdown code block currently in SKILL.md under "### claude_instructions/component-structure.md">

  ## env-vars

  <paste the exact markdown code block currently in SKILL.md under "### claude_instructions/env-vars.md">
  ```

  Verify: `grep -c "NEXT_PUBLIC_" skills/web-development-setup/rule-file-templates.md` must be ≥ 1 after the paste.

- [ ] **Step 3: Create `framework-defaults.md`**

  Create `skills/web-development-setup/framework-defaults.md`:

  ```markdown
  > Consumed by web-development-setup/SKILL.md at Step 4. Do not invoke directly.

  # Framework Defaults — Web Development Setup

  ## Implied Styling and Deploy Targets

  <paste the full "Step 4: Derive Implied Defaults" matrix table currently in SKILL.md, plus the static-site and backend-only notes that follow>

  Record the implied styling + deploy target as `styling_stack` and `deploy_target_hint` — they go into CLAUDE.md pointers but are not asked as separate questions.

  ## Public Env-Var Prefix Table

  <paste the "Framework conventions for client-exposed values" table currently inside the claude_instructions/env-vars.md block; the same table serves both as a generator hint and as user-facing rule content>
  ```

  Note: the env-var prefix table is duplicated here because it is read at Step 4 (to inform `styling_stack` logic) and at Step 6 (as part of the rule-file body). Leave the duplicate; it costs ~20 lines and keeps each sibling self-contained.

- [ ] **Step 4: Create `gitignore-block.md`**

  Create `skills/web-development-setup/gitignore-block.md`:

  ```markdown
  > Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

  # Gitignore and .env.example — Web Development Setup

  ## .gitignore block

  Append this delimited block at the end of the user's `.gitignore`. If the marker block already exists, replace only the content between the markers.

  <paste the exact `.gitignore` fenced block currently in SKILL.md under "### .gitignore">

  Note: `.env.example` (without `.local`) is intentionally NOT ignored — it serves as the committed template listing every required variable with placeholder values.

  ## .env.example scaffold

  If `.env.example` is missing, emit this minimal one based on the stack:

  <paste the `.env.example` fenced block currently in SKILL.md under "### Optional: .env.example scaffold">
  ```

- [ ] **Step 5: Create `document-skeletons.md`**

  Create `skills/web-development-setup/document-skeletons.md`:

  ```markdown
  > Consumed by web-development-setup/SKILL.md at Step 6. Do not invoke directly.

  # Document Skeletons — Web Development Setup

  ## package.json (when missing and Q1 ≠ backend-only-Python-or-Go)

  <paste the "package.json (minimal, only if none exists ...)" fenced block currently in SKILL.md, including the surrounding instructions>

  ## Install commands by stack

  <paste the per-Q2 / per-Q6 / per-Q7 / per-Q5 install-command bullet list currently in SKILL.md immediately after the package.json block, and the `<pm>` expansion note>

  ## pyproject.toml (when Q3 = Python backend and `uv_available: true`)

  <paste the `pyproject.toml` fenced block and the `uv add` commands currently under "### pyproject.toml">
  ```

- [ ] **Step 6: Rewrite `skills/web-development-setup/SKILL.md`**

  Use the Edit tool step by step (one Edit per section). The resulting file must keep the front matter, the intro, the language block, the existing-CLAUDE.md block, Steps 1, 2, 3, 5, 7, 8, 9 unchanged in substance, and replace Step 4 and Step 6 with the sibling-reference shape below.

  **Replacement for the current Step 4 body** (from `## Step 4: Derive Implied Defaults (do NOT ask)` through the line ending `… but are not asked as separate questions.`):

  ```markdown
  ## Step 4: Derive Implied Defaults (do NOT ask)

  Read `framework-defaults.md`. Use the matrix there to derive `styling_stack` and `deploy_target_hint` from Q1 and Q2. These are NOT asked as separate questions.
  ```

  **Replacement for the Step 6 artifact subsections** (all four sub-blocks `### claude_instructions/api-conventions.md`, `### claude_instructions/component-structure.md`, `### claude_instructions/env-vars.md`, `### package.json ...`, `### pyproject.toml ...`, `### .gitignore`, `### Optional: .env.example scaffold`):

  ```markdown
  ### .claude/rules/api-conventions.md

  Read `rule-file-templates.md` and write its `api-conventions` section to `.claude/rules/api-conventions.md`. Skip the write if the file already exists (log `Skipped .claude/rules/api-conventions.md (already exists)`).

  ### .claude/rules/component-structure.md

  Read `rule-file-templates.md` and write its `component-structure` section to `.claude/rules/component-structure.md`. Skip the write if the file already exists.

  ### .claude/rules/env-vars.md

  Read `rule-file-templates.md` and write its `env-vars` section to `.claude/rules/env-vars.md`. Skip the write if the file already exists.

  ### package.json and install commands

  Read `document-skeletons.md`. If `package.json` is missing and Q1 ≠ backend-only-Python-or-Go, emit the scaffold from the `package.json` section with `<pm>` expanded from Q4. Print the install commands from the "Install commands by stack" section matching Q2 / Q5 / Q6 / Q7. NEVER execute install commands without explicit user consent. If `pm_available: false`, print the commands as a manual checklist.

  ### pyproject.toml (only if Q3 = Python backend and `uv_available: true`)

  Read `document-skeletons.md` and emit its `pyproject.toml` section plus the `uv add` commands. If `uv_available: false`, print as instructions only.

  ### .gitignore and .env.example

  Read `gitignore-block.md`. Append the `.gitignore` block at the end of the user's `.gitignore` (delimited markers; replace only the content between them if already present). If `.env.example` is missing, emit the `.env.example` scaffold from the same file.
  ```

  **Keep the existing `### .claude/settings.json` block inline** — it has per-Q4 / per-Q5 / per-Q6 / per-Q7 / per-Q3 / per-Q2 branching that fits the "decision branch" rule and is ≤ 35 lines when counted alone.

  **Add the Supporting-Files block** directly after the existing-CLAUDE.md block and before `## Step 1: Install Dependencies`:

  ```markdown
  ## Supporting Files

  Read these on-demand at the step that invokes them. Do not read eagerly.

  - `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 6)
  - `framework-defaults.md` — Q1/Q2-conditional styling and deploy-target matrix (Step 4), plus public env-var prefix table
  - `gitignore-block.md` — the `.gitignore` block and `.env.example` scaffold (Step 6)
  - `document-skeletons.md` — `package.json`, `pyproject.toml`, and per-stack install commands (Step 6)
  ```

  **Rename the three pointers** inside the CLAUDE.md artifact block (the one emitted to the user's project) from `claude_instructions/` to `.claude/rules/`. If the rules-convention migration (Task 3 of the companion initiative, issue #12) has already landed, this is a no-op — verify with `grep -c "claude_instructions/" skills/web-development-setup/SKILL.md`; if the count is > 0, update those references to `.claude/rules/` as part of this task. The modularization refactor must not leave stale paths behind.

- [ ] **Step 7: Verify SKILL.md shrank and parity holds**

  Run: `wc -l skills/web-development-setup/SKILL.md`
  Expected: ≤ 260.

  Run the same distinctive-token greps from Step 1, this time across SKILL.md **plus** all four siblings:

  ```bash
  grep -c "NEXT_PUBLIC_" skills/web-development-setup/SKILL.md skills/web-development-setup/rule-file-templates.md skills/web-development-setup/framework-defaults.md skills/web-development-setup/gitignore-block.md skills/web-development-setup/document-skeletons.md
  grep -c "api-conventions" skills/web-development-setup/*.md
  grep -c "component-structure" skills/web-development-setup/*.md
  grep -c "env-vars" skills/web-development-setup/*.md
  grep -c "# onboarding-agent: web-development" skills/web-development-setup/*.md
  ```

  Each aggregate count must be ≥ the pre-refactor count recorded in Step 1.

  Run: `grep -c "Supporting Files" skills/web-development-setup/SKILL.md`
  Expected: `1`.

  Run: ``grep -c "Read `" skills/web-development-setup/SKILL.md``
  Expected: ≥ 5 (one for framework-defaults + three for rule-file-templates + at least one each for gitignore-block and document-skeletons).

- [ ] **Step 8: Commit**

  ```bash
  git add skills/web-development-setup/
  git commit -m "refactor(web-development-setup): modularize SKILL.md into topic-domain siblings"
  ```

---

## Task 3 — Modularize `skills/academic-writing-setup/SKILL.md`

**Files:**

- Create: `skills/academic-writing-setup/rule-file-templates.md`
- Create: `skills/academic-writing-setup/document-skeletons.md`
- Create: `skills/academic-writing-setup/gitignore-block.md`
- Create: `skills/academic-writing-setup/optional-integrations.md`
- Modify: `skills/academic-writing-setup/SKILL.md`

- [ ] **Step 1: Baseline**

  Run: `wc -l skills/academic-writing-setup/SKILL.md`
  Expected: ~463.

  Record pre-refactor token counts:

  ```bash
  grep -c "\\\\cite{" skills/academic-writing-setup/SKILL.md
  grep -c "biblatex" skills/academic-writing-setup/SKILL.md
  grep -c "Better BibTeX" skills/academic-writing-setup/SKILL.md
  grep -c "# onboarding-agent: academic-writing" skills/academic-writing-setup/SKILL.md
  grep -c "Overleaf" skills/academic-writing-setup/SKILL.md
  ```

- [ ] **Step 2: Create `rule-file-templates.md`**

  Create `skills/academic-writing-setup/rule-file-templates.md`:

  ```markdown
  > Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

  # Rule File Templates — Academic Writing Setup

  ## writing-style

  <paste the exact markdown code block currently in SKILL.md under "### claude_instructions/writing-style.md">

  ## citation-rules

  <paste the exact markdown code block currently in SKILL.md under "### claude_instructions/citation-rules.md">
  ```

- [ ] **Step 3: Create `document-skeletons.md`**

  Create `skills/academic-writing-setup/document-skeletons.md`:

  ```markdown
  > Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

  # Document Skeletons — Academic Writing Setup

  ## Directory scaffold

  <paste the "Directory scaffold" bullet list currently in SKILL.md, both LaTeX and Typst variants, including the "Do not scaffold any directory that already exists" note>

  ## main.tex skeleton (LaTeX stacks only: Q3 = A, B, or C)

  <paste the full `main.tex` fenced block currently in SKILL.md, including the biblatex-style mapping bullet list that follows it>

  Seed `sections/00-abstract.tex` and `sections/01-introduction.tex` as empty stubs with a one-line comment:

  <paste the two tiny one-line-comment fenced blocks currently in SKILL.md>

  ## main.typ skeleton (Typst only: Q3 = D)

  <paste the `main.typ` fenced block plus the CSL-style mapping bullet list>

  ## bib/references.bib

  <paste the `references.bib` commented-example fenced block>
  ```

- [ ] **Step 4: Create `gitignore-block.md`**

  Create `skills/academic-writing-setup/gitignore-block.md`:

  ```markdown
  > Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

  # Gitignore — Academic Writing Setup

  <paste the `.gitignore` fenced block currently in SKILL.md under "### .gitignore", plus the trailing note about `main.pdf` intentionally not being ignored>
  ```

- [ ] **Step 5: Create `optional-integrations.md`**

  Create `skills/academic-writing-setup/optional-integrations.md`:

  ```markdown
  > Consumed by academic-writing-setup/SKILL.md at Step 4. Do not invoke directly.

  # Optional Integrations — Academic Writing Setup

  ## .pre-commit-config.yaml (chktex + vale)

  <paste the `.pre-commit-config.yaml` fenced block plus the two warning lines about chktex_available / vale_available and the `pygmentize` / `uv tool run` note>

  ## Overleaf + Git bridge (only if Q3 = B)

  <paste the Overleaf instruction fenced block currently in SKILL.md>

  ## Template pointer (only if Q2 = A or B)

  <paste the "Template pointer" bullets — thesis and paper variants>

  ## Knowledge-base bridge

  <paste the "Knowledge-base bridge (mention only)" paragraph>
  ```

- [ ] **Step 6: Rewrite `skills/academic-writing-setup/SKILL.md`**

  Replace the Step 4 subsections `### claude_instructions/writing-style.md`, `### claude_instructions/citation-rules.md`, `### Directory scaffold`, `### main.tex skeleton …`, `### main.typ skeleton …`, `### bib/references.bib`, `### .gitignore`, `### Optional: .pre-commit-config.yaml …`, `### Optional: Overleaf + Git bridge …`, `### Optional: Template pointer …`, `### Optional: Knowledge-base bridge …` with the following sibling-reference shape:

  ```markdown
  ### .claude/rules/writing-style.md

  Read `rule-file-templates.md` and write its `writing-style` section to `.claude/rules/writing-style.md`. Skip the write if the file already exists.

  ### .claude/rules/citation-rules.md

  Read `rule-file-templates.md` and write its `citation-rules` section to `.claude/rules/citation-rules.md`. Skip the write if the file already exists.

  ### Document scaffold and skeletons

  Read `document-skeletons.md`. Create the directory scaffold (LaTeX layout if Q3 ∈ {A, B, C}; Typst layout if Q3 = D); leave any already-existing directory untouched. If `main.tex` is missing and Q3 ∈ {A, B, C}, emit the `main.tex` skeleton from the same file with `<biblatex-style>` substituted per Q4. If `main.typ` is missing and Q3 = D, emit the `main.typ` skeleton with `<csl-style>` substituted per Q4. If `bib/references.bib` is missing, emit the commented-example entry.

  ### .gitignore

  Read `gitignore-block.md` and append its block to the user's `.gitignore` (delimited markers; replace only the content between them if already present).

  ### Optional integrations

  Read `optional-integrations.md`. Emit the `.pre-commit-config.yaml` scaffold if `chktex_available` or `vale_available` is true OR the user requested it, and print the matching missing-tool warnings. If Q3 = B, print the Overleaf + Git bridge instructions. If Q2 = A or B, print the template pointer note. Mention the knowledge-base bridge only when the user references an existing vault / wiki.
  ```

  **Add the Supporting-Files block** after the existing-CLAUDE.md block and before `## Step 1: Install Dependencies`:

  ```markdown
  ## Supporting Files

  Read these on-demand at the step that invokes them. Do not read eagerly.

  - `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 4)
  - `document-skeletons.md` — directory scaffold, `main.tex`, `main.typ`, `bib/references.bib` (Step 4)
  - `gitignore-block.md` — the `.gitignore` block (Step 4)
  - `optional-integrations.md` — `.pre-commit-config.yaml`, Overleaf instructions, template pointer, KB bridge (Step 4)
  ```

  **Update pointers inside the CLAUDE.md artifact block** from `claude_instructions/` to `.claude/rules/` if not already done. Grep: `grep -c "claude_instructions/" skills/academic-writing-setup/SKILL.md` must be `0` afterwards.

- [ ] **Step 7: Verify**

  Run: `wc -l skills/academic-writing-setup/SKILL.md`
  Expected: ≤ 240.

  Run parity greps across SKILL.md + all four siblings:

  ```bash
  grep -c "\\\\cite{" skills/academic-writing-setup/*.md
  grep -c "biblatex" skills/academic-writing-setup/*.md
  grep -c "Better BibTeX" skills/academic-writing-setup/*.md
  grep -c "# onboarding-agent: academic-writing" skills/academic-writing-setup/*.md
  grep -c "Overleaf" skills/academic-writing-setup/*.md
  ```

  Each aggregate count must be ≥ the pre-refactor count.

  Run: `grep -c "Supporting Files" skills/academic-writing-setup/SKILL.md`
  Expected: `1`.

  Run: ``grep -c "Read `" skills/academic-writing-setup/SKILL.md``
  Expected: ≥ 4.

- [ ] **Step 8: Commit**

  ```bash
  git add skills/academic-writing-setup/
  git commit -m "refactor(academic-writing-setup): modularize SKILL.md into topic-domain siblings"
  ```

---

## Task 4 — Modularize `skills/data-science-setup/SKILL.md`

**Files:**

- Create: `skills/data-science-setup/rule-file-templates.md`
- Create: `skills/data-science-setup/stack-scaffolds.md`
- Create: `skills/data-science-setup/gitignore-block.md`
- Create: `skills/data-science-setup/notebook-hygiene.md`
- Modify: `skills/data-science-setup/SKILL.md`

- [ ] **Step 1: Baseline**

  Run: `wc -l skills/data-science-setup/SKILL.md`
  Expected: ~341.

  Record pre-refactor token counts:

  ```bash
  grep -c "uv add" skills/data-science-setup/SKILL.md
  grep -c "nbqa" skills/data-science-setup/SKILL.md
  grep -c "mlflow" skills/data-science-setup/SKILL.md
  grep -c "data/raw" skills/data-science-setup/SKILL.md
  grep -c "# onboarding-agent: data-science" skills/data-science-setup/SKILL.md
  ```

- [ ] **Step 2: Create `rule-file-templates.md`**

  Create `skills/data-science-setup/rule-file-templates.md`:

  ```markdown
  > Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

  # Rule File Templates — Data Science Setup

  ## data-schema

  <paste the markdown code block currently in SKILL.md under "### claude_instructions/data-schema.md">

  ## evaluation-protocol

  <paste the markdown code block currently in SKILL.md under "### claude_instructions/evaluation-protocol.md">
  ```

- [ ] **Step 3: Create `stack-scaffolds.md`**

  Create `skills/data-science-setup/stack-scaffolds.md`:

  ```markdown
  > Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

  # Stack Scaffolds — Data Science Setup

  ## pyproject.toml (only if Q1 includes Python and `uv_available: true`)

  <paste the `pyproject.toml` fenced block currently in SKILL.md under "### pyproject.toml">

  ## uv add commands by answer

  <paste the "Always: `uv add …`" bullet list plus the per-Q2 / per-Q3 / per-Q4 / per-Q6 conditional bullets and the `uv_available: false` note>

  ## .claude/settings.json — base permissions

  <paste the base `.claude/settings.json` fenced block currently in SKILL.md under "### .claude/settings.json (Python stacks)">

  ## .claude/settings.json — per-answer adaptations

  <paste the per-Q2 / per-Q4 / per-Q1 adaptation bullet list and the merge-dedupe note>

  ## Directory scaffold (only if Q5 = yes)

  <paste the "Create:" fenced directory-tree block plus the `data/README.md` explanation paragraph>
  ```

- [ ] **Step 4: Create `gitignore-block.md`**

  Create `skills/data-science-setup/gitignore-block.md`:

  ```markdown
  > Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

  # Gitignore — Data Science Setup

  <paste the `.gitignore` fenced block currently in SKILL.md under "### .gitignore">
  ```

- [ ] **Step 5: Create `notebook-hygiene.md`**

  Create `skills/data-science-setup/notebook-hygiene.md`:

  ```markdown
  > Consumed by data-science-setup/SKILL.md at Step 4. Do not invoke directly.

  # Notebook Hygiene — Data Science Setup

  ## .pre-commit-config.yaml (only if Q6 = yes)

  <paste the `.pre-commit-config.yaml` fenced block currently in SKILL.md under "### Notebook hygiene (only if Q6 = yes)">

  If `pre-commit` is not installed, print: "Run `uv add --dev pre-commit && uv run pre-commit install` to activate the hooks."
  ```

- [ ] **Step 6: Rewrite `skills/data-science-setup/SKILL.md`**

  Replace the Step 4 subsections `### claude_instructions/data-schema.md`, `### claude_instructions/evaluation-protocol.md`, `### pyproject.toml …`, `### .claude/settings.json (Python stacks)`, `### Directory scaffold …`, `### .gitignore`, `### Notebook hygiene …` with the following:

  ```markdown
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
  ```

  **Add the Supporting-Files block** after the existing-CLAUDE.md block and before `## Step 1: Install Dependencies`:

  ```markdown
  ## Supporting Files

  Read these on-demand at the step that invokes them. Do not read eagerly.

  - `rule-file-templates.md` — bodies of the `.claude/rules/*.md` files (Step 4)
  - `stack-scaffolds.md` — `pyproject.toml`, `uv add` commands, `.claude/settings.json` permissions, directory scaffold (Step 4)
  - `gitignore-block.md` — the `.gitignore` block (Step 4)
  - `notebook-hygiene.md` — `.pre-commit-config.yaml` for nbstripout + nbqa (Step 4)
  ```

  **Update pointers inside the CLAUDE.md artifact block** from `claude_instructions/` to `.claude/rules/` if not already done. Grep: `grep -c "claude_instructions/" skills/data-science-setup/SKILL.md` must be `0` afterwards.

- [ ] **Step 7: Verify**

  Run: `wc -l skills/data-science-setup/SKILL.md`
  Expected: ≤ 220.

  Run parity greps across SKILL.md + all four siblings:

  ```bash
  grep -c "uv add" skills/data-science-setup/*.md
  grep -c "nbqa" skills/data-science-setup/*.md
  grep -c "mlflow" skills/data-science-setup/*.md
  grep -c "data/raw" skills/data-science-setup/*.md
  grep -c "# onboarding-agent: data-science" skills/data-science-setup/*.md
  ```

  Each aggregate count must be ≥ the pre-refactor count.

  Run: `grep -c "Supporting Files" skills/data-science-setup/SKILL.md`
  Expected: `1`.

  Run: ``grep -c "Read `" skills/data-science-setup/SKILL.md``
  Expected: ≥ 5.

- [ ] **Step 8: Commit**

  ```bash
  git add skills/data-science-setup/
  git commit -m "refactor(data-science-setup): modularize SKILL.md into topic-domain siblings"
  ```

---

## Task 5 — Verification

No commit. Final gate before the PR.

- [ ] **Step 1: Threshold check**

  Run:
  ```bash
  wc -l skills/web-development-setup/SKILL.md skills/academic-writing-setup/SKILL.md skills/data-science-setup/SKILL.md
  ```
  Expected: each value ≤ 300, and specifically ≤ 260 / ≤ 240 / ≤ 220.

- [ ] **Step 2: Sibling presence**

  Run:
  ```bash
  ls skills/web-development-setup/
  ls skills/academic-writing-setup/
  ls skills/data-science-setup/
  ```

  Expected files per directory:
  - web-development-setup: `SKILL.md`, `rule-file-templates.md`, `framework-defaults.md`, `gitignore-block.md`, `document-skeletons.md`
  - academic-writing-setup: `SKILL.md`, `rule-file-templates.md`, `document-skeletons.md`, `gitignore-block.md`, `optional-integrations.md`
  - data-science-setup: `SKILL.md`, `rule-file-templates.md`, `stack-scaffolds.md`, `gitignore-block.md`, `notebook-hygiene.md`

- [ ] **Step 3: Supporting-Files blocks**

  Run:
  ```bash
  grep -c "## Supporting Files" skills/web-development-setup/SKILL.md skills/academic-writing-setup/SKILL.md skills/data-science-setup/SKILL.md
  ```
  Expected: each file reports `1`.

- [ ] **Step 4: Sibling consumer notes**

  Run:
  ```bash
  grep -l "Do not invoke directly" skills/web-development-setup/*.md skills/academic-writing-setup/*.md skills/data-science-setup/*.md
  ```
  Expected: every sibling (12 files) appears; the SKILL.md files do not appear.

- [ ] **Step 5: Authoring doc**

  Run: `grep -c "SKILL.md Modularization" CLAUDE.md`
  Expected: `1`.

  Run: `grep -c "300 lines" CLAUDE.md`
  Expected: ≥ 1.

- [ ] **Step 6: Manifest untouched**

  Run: `git diff origin/main -- .claude-plugin/plugin.json`
  Expected: no output (the manifest is unchanged by this PR).

- [ ] **Step 7: No stale claude_instructions references in refactored skills**

  Run:
  ```bash
  grep -l "claude_instructions/" skills/web-development-setup/ skills/academic-writing-setup/ skills/data-science-setup/ -r
  ```
  Expected: no output. (Any lingering references from before the rules-convention migration must be cleaned up as part of this refactor.)

- [ ] **Step 8: Spec Success Criteria walkthrough**

  Open `docs/superpowers/specs/2026-04-21-skill-modularization-design.md` and tick every bullet in "Success Criteria" against the current branch state. Any unmet criterion blocks the PR.

- [ ] **Step 9: Open PR**

  ```bash
  gh pr create --title "Modularize oversized SKILL.md files (web, academic-writing, data-science)" --body "$(cat <<'EOF'
  ## Summary

  - Split three oversized SKILL.md files into thin orchestration prompts plus topic-domain sibling files.
  - Lock a 300-line threshold, canonical sibling-filename table, extraction boundary, and reference pattern into `CLAUDE.md`.
  - No change to `.claude-plugin/plugin.json`, to any command, or to the artifacts the skills write into the user's project.

  ## Spec

  `docs/superpowers/specs/2026-04-21-skill-modularization-design.md`

  ## Test plan

  - [x] `wc -l` on the three refactored SKILL.md files returns values below their per-skill caps (260 / 240 / 220).
  - [x] Parity greps on distinctive tokens match pre-refactor counts across SKILL.md + siblings.
  - [x] Every sibling opens with "Consumed by <skill>/SKILL.md".
  - [x] Every refactored SKILL.md has a `## Supporting Files` block and at least four `` Read `<file>` `` imperatives.
  - [x] `.claude-plugin/plugin.json` unchanged.

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  EOF
  )"
  ```

---

## Self-Review (performed at plan authoring time)

- **Spec coverage:** Every Success Criterion maps to a verification step. Line count → Task 5 Step 1. Sibling presence → Task 5 Step 2. Generated-output parity → Tasks 2–4 Step 7. Supporting-Files block → Task 5 Step 3. Authoring doc → Task 5 Step 5. Manifest untouched → Task 5 Step 6.
- **Consistent naming:** `rule-file-templates.md`, `gitignore-block.md`, `document-skeletons.md`, `framework-defaults.md`, `stack-scaffolds.md`, `optional-integrations.md`, `notebook-hygiene.md` — each filename appears identically in the spec's "Affected Skills" section, this plan's File Structure, and in every task that references it. No typos, no plural/singular drift.
- **Placeholders:** The `<paste …>` markers in Tasks 2–4 describe exactly which fenced block of the current SKILL.md to copy; no content is left TBD. Implementers copy bytes; they do not rewrite.
- **Commit count:** Five commits total (Task 1, Task 2, Task 3, Task 4; Task 5 has no commit). Matches the repo's "one commit per task group" style.
- **Known soft edge:** Task 2 Step 6 and Task 3 Step 6 include a "rewrite front-matter pointers from `claude_instructions/` to `.claude/rules/` if not already done" clause. This is defensive — it protects against the rules-convention migration (issue #12) landing in either order relative to this PR. If #12 has already merged, those lines are no-ops.
