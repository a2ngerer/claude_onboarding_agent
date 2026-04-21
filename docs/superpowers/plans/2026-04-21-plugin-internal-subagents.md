# Plugin-Internal Subagents — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship two plugin-internal Claude Code subagents (`repo-scanner`, `upgrade-planner`) as files in `.claude/agents/`, add the authoring rules to `CLAUDE.md`, and verify both files satisfy the spec's grep-testable success criteria. No consumer skill is refactored in this initiative.

**Architecture:** Markdown files with YAML frontmatter under `.claude/agents/` in the plugin root. Claude Code discovers subagents by convention at plugin-load time; no `plugin.json` change is needed or performed. Authoring rules live in the plugin's own `CLAUDE.md` under "Skill Authoring Rules".

**Tech Stack:** Markdown, YAML frontmatter, Claude Code plugin framework. Verification is grep-based (static) plus a documented manual sanity check via the Agent tool.

**Spec:** `docs/superpowers/specs/2026-04-21-plugin-internal-subagents-design.md` — read it first. Every task below references decisions made there.

---

## Conventions for this plan

- Commit messages follow the existing repo style (`feat(scope):`, `docs(scope):`, `chore(scope):`). Three commits total, one per task.
- "Test" for this scaffolding change = `grep`/`test -f` before and after. "Failing test" = the file or content is absent. "Passing test" = the file exists with the expected content.
- **Never** use `git commit --no-verify`. If a pre-commit hook fails, fix the underlying issue.
- Language for all committed artifacts: English (repo rule).
- Subagent names are fixed across the plan: `repo-scanner`, `upgrade-planner`. Never abbreviate, never rename mid-plan.

## File Structure

**New:**
- `.claude/agents/repo-scanner.md` — read-only repo-signal subagent
- `.claude/agents/upgrade-planner.md` — read-only upgrade-diff subagent

**Modified:**
- `CLAUDE.md` (repo root) — add "Subagent Authoring Rules" subsection under "Skill Authoring Rules"

**Unchanged (explicitly):**
- `.claude-plugin/plugin.json` — no manifest change in this initiative
- All `skills/*/SKILL.md` — no consumer wiring in this initiative
- `.claude/commands/*` — unchanged

---

## Task 1 — Create `repo-scanner` subagent

**Files:**
- Create: `.claude/agents/repo-scanner.md`

- [ ] **Step 1: Verify `.claude/agents/` does not yet contain the target file**

Run: `test -f .claude/agents/repo-scanner.md && echo EXISTS || echo MISSING`
Expected: `MISSING`.

Run: `ls .claude/agents/ 2>/dev/null || echo NO_DIR`
Expected: `NO_DIR` on a fresh branch (the directory has not been created yet) — or, if another task created it, an empty listing.

- [ ] **Step 2: Create the directory if needed**

Run: `mkdir -p .claude/agents`

- [ ] **Step 3: Write `.claude/agents/repo-scanner.md` with the following content (exact)**

~~~markdown
---
name: repo-scanner
description: Read-only subagent that scans a user project for language, framework, corpus-size, and use-case signals. Returns one structured report; never writes files.
tools: Bash, Glob, Grep, Read
model: opus
---

# Repo Scanner

## Role

Scan the user project rooted at the current working directory and return a single structured report summarizing what Claude should treat the project as. This subagent is read-only: it infers signals, it does not modify files, and it does not dispatch other subagents.

## Inputs

The caller provides, in the `prompt:` field:

- Either an explicit instruction ("scan the current directory") or nothing. The subagent always scans the current working directory — there is no target path argument.
- Optionally: a hint about which signals are most relevant. Hints are advisory; the scanner always returns every field in the output contract.

## Output Contract

Return exactly one fenced code block tagged `repo-scan`, containing YAML-style fields. Do not return prose before or after the block. Example of the exact shape:

```repo-scan
inferred_use_case: web-development
signals:
  - package.json
  - next.config.ts
  - "package.json:next"
  - "app/page.tsx"
graphify_candidate: false
existing_claude_md: true
existing_agents_md: false
repo_size_bucket: small
```

Field definitions:

- `inferred_use_case` — one of: `coding`, `web-development`, `data-science`, `knowledge-base`, `office`, `research`, `academic-writing`, `content-creator`, `devops`, `design`, `graphify`, `unknown`. Use `unknown` when no signal is strong enough to commit to a single use case.
- `signals` — a list of strings identifying the detected evidence (file names, directory names, or `manifest:dependency` pairs). At least the strongest three signals; at most ten.
- `graphify_candidate` — `true` if the repo has either > 1000 source files across multiple languages OR > 100 PDFs/Markdown notes under `docs/` / `raw/` / `notes/`. Otherwise `false`.
- `existing_claude_md` — `true` if `./CLAUDE.md` exists.
- `existing_agents_md` — `true` if `./AGENTS.md` exists.
- `repo_size_bucket` — one of: `tiny` (< 20 non-hidden files), `small` (20–200), `medium` (200–2000), `large` (> 2000). Count via `find . -not -path './.*' -type f | wc -l` or equivalent.

## Detection Heuristics (mirror of `onboarding/SKILL.md` Step 2)

- Count files with extensions `.py`, `.ts`, `.js`, `.go`, `.rs`, `.rb`, `.java`, `.cs` → coding signal.
- Package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt`) → strong coding signal.
- Web framework configs (`next.config.{js,mjs,ts}`, `vite.config.{js,mjs,ts}`, `astro.config.{mjs,ts}`, `remix.config.{js,ts}`, `svelte.config.{js,ts}`, `nuxt.config.{js,ts}`) OR framework deps in `package.json` (`next`, `react-dom`, `vue`, `svelte`, `@sveltejs/kit`, `astro`, `@remix-run/*`, `solid-js`, `@nuxt/kit`) → web-development signal. Dominates a generic coding signal when present.
- `.ipynb` files, `notebooks/`, `data/raw/`, or DS deps (`pandas`/`polars`/`numpy`/`scikit-learn`/`torch`/`jax`) in `pyproject.toml` → data-science signal. Dominates a generic Python coding signal.
- `.tex`, `.bib` files → research signal.
- `sections/` folder, `bib/` folder, `main.tex`/`main.typ`, or `.typ` alongside `.bib` → academic-writing signal. Dominates a generic research signal.
- `*.docx`, `*.pptx`, `*.pdf`, `*.xlsx` files → office signal.
- `notes/`, `vault/`, `wiki/`, `obsidian/` directory → knowledge-base signal.

Apply the dominance rules in order. The strongest single signal wins. If two signals tie, prefer the more specific one (web-development over coding, academic-writing over research, data-science over coding).

## Constraints

- **Read-only.** Do not use `Write` or `Edit`. Do not invoke `Bash` commands that modify state — no `rm`, `mv`, `cp`, `touch`, `mkdir -p` (except `/tmp`), no `>`-redirects into project files, no `git add`/`commit`/`push`/`mv`.
- **No recursive dispatch.** Do not invoke the Agent tool. Do not call another subagent from inside this one.
- **No prose.** Return the fenced `repo-scan` block and nothing else. No preamble, no summary, no explanation.
- **Bounded cost.** Cap `find` output at the first ~5000 paths. If the repo is larger than that, infer from the head and set `repo_size_bucket: large` without exhaustive enumeration.

## Failure Mode

If a signal cannot be determined (e.g., `find` fails, a required manifest is unreadable), emit `unknown` for `inferred_use_case` and include in `signals` a string of the form `error:<short description>`. Never return a partial block that omits contracted fields, and never silently skip a field.
~~~

- [ ] **Step 4: Verify the file exists with the expected frontmatter**

Run: `test -f .claude/agents/repo-scanner.md && echo OK`
Expected: `OK`.

Run: `grep -c "^name: repo-scanner$" .claude/agents/repo-scanner.md`
Expected: `1`.

Run: `grep -c "^model: opus$" .claude/agents/repo-scanner.md`
Expected: `1`.

Run: `grep -E "^tools:.*\b(Write|Edit|NotebookEdit)\b" .claude/agents/repo-scanner.md`
Expected: no output (read-only tool-set).

Run: `grep -c "^## " .claude/agents/repo-scanner.md`
Expected: `>= 5` (Role, Inputs, Output Contract, Detection Heuristics, Constraints, Failure Mode).

Run: `grep -c '^```repo-scan$' .claude/agents/repo-scanner.md`
Expected: `1` (the concrete output example in the Output Contract section).

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/repo-scanner.md
git commit -m "feat(agents): add repo-scanner plugin-internal subagent"
```

---

## Task 2 — Create `upgrade-planner` subagent

**Files:**
- Create: `.claude/agents/upgrade-planner.md`

- [ ] **Step 1: Verify the target file does not yet exist**

Run: `test -f .claude/agents/upgrade-planner.md && echo EXISTS || echo MISSING`
Expected: `MISSING`.

- [ ] **Step 2: Write `.claude/agents/upgrade-planner.md` with the following content (exact)**

~~~markdown
---
name: upgrade-planner
description: Read-only subagent that enumerates plugin-owned delimited sections in a user project, diffs each against the canonical current template, and returns the list of proposed changes. Never writes files.
tools: Bash, Glob, Grep, Read
model: opus
---

# Upgrade Planner

## Role

Walk the user project's plugin-owned delimited sections, compare each on-disk body against the canonical current template supplied by the caller, and return a list of proposed changes (one entry per section with a non-empty diff). This subagent is read-only: it plans, it does not apply.

## Inputs

The caller provides, in the `prompt:` field:

- `detected_skills` — list of skill slugs (e.g., `coding-setup`, `web-development-setup`). Determines which sections to look at.
- `current_version` — plugin version string (used only to annotate the returned report; the subagent does not re-resolve it).
- `canonical_templates` — a mapping from `(skill, section)` keys to the canonical current body. Provided inline by the caller; the subagent does not fetch templates on its own.
- Optionally: `candidate_files` — explicit override of which paths to scan. If omitted, scan the default candidate list below.

## Default Candidate Files

When `candidate_files` is not provided, scan these paths (skip any that do not exist on disk):

- `./CLAUDE.md`
- `./AGENTS.md`
- `./.gitignore`
- `./.claude/settings.json`
- `./.claude/rules/*.md`

## Output Contract

Return exactly one fenced code block tagged `upgrade-plan`, containing a YAML list. Do not return prose before or after the block.

```upgrade-plan
version: <current_version echoed from input>
proposed_changes:
  - change_id: cma-01
    setup_type: coding
    file: ./CLAUDE.md
    section: claude-md
    rationale: "Template body drifted from canonical."
    diff: |
      @@ -12,3 +12,3 @@
      -old line
      +new line
  - change_id: cma-02
    setup_type: coding
    file: ./.gitignore
    section: coding-setup
    rationale: "New ignore pattern added in plugin v1.1."
    diff: |
      @@ -5,0 +6,1 @@
      +.venv/
summary:
  total_sections_examined: 4
  total_changes: 2
  files_with_changes:
    - ./CLAUDE.md
    - ./.gitignore
```

Field definitions:

- `version` — echo of `current_version` from input.
- `proposed_changes` — list, one entry per section whose on-disk body differs from the canonical template. Empty list if nothing drifted.
- `change_id` — stable identifier: `<file-shorthand>-<index>` (e.g., `cma-01` for `CLAUDE.md` change #1, `gi-02` for `.gitignore` change #2). Zero-padded to two digits.
- `file` — relative path from the project root.
- `section` — the `section=` attribute from the delimiter (or a synthetic name like `<slug>` for `.gitignore` blocks and `<slug>` for `_onboarding_agent` JSON keys).
- `rationale` — one short sentence.
- `diff` — unified diff with 3 lines of context.

## Delimiter Recognition

Match the delimiters exactly as documented in `skills/upgrade/SKILL.md` Pass 2:

- **Markdown** (`CLAUDE.md`, `AGENTS.md`, `.claude/rules/*.md`):
  - Attributed: `<!-- onboarding-agent:start setup=<type> skill=<slug> section=<name> -->` … `<!-- onboarding-agent:end -->`
  - Legacy: `<!-- onboarding-agent:start -->` … `<!-- onboarding-agent:end -->`
- **`.gitignore`**: `# onboarding-agent: <slug> — start` … `# onboarding-agent: <slug> — end`.
- **`.claude/settings.json`**: top-level `_onboarding_agent.<slug>.allow_owned` list. The "section" is that list; the "diff" compares `allow_owned` against the canonical set.

Skip any file without a plugin marker. Do not insert new markers — that is the caller's responsibility, not this subagent's.

## Constraints

- **Read-only.** Do not use `Write` or `Edit`. Do not invoke destructive `Bash`.
- **No recursive dispatch.** Do not invoke the Agent tool.
- **Answer-derived values are preserved.** If the canonical template contains placeholders that the on-disk body fills in (project stack, citation style, …), compare only the structural scaffolding, not the filled values. Differences limited to filled values do NOT produce a proposed change.
- **No prose.** Return the `upgrade-plan` fenced block and nothing else.
- **Bounded output.** If `proposed_changes` exceeds 50 entries, truncate to the first 50 sorted by (file, section) and add `truncated: true` under `summary`. The caller can re-run with narrower `candidate_files` if needed.

## Failure Mode

If a candidate file cannot be read (permission error, binary content), emit a `proposed_changes` entry with `change_id: err-NN`, `file: <path>`, `rationale: "error:<short description>"`, and an empty `diff:`. Never omit the error silently. If the `canonical_templates` input is missing for a skill in `detected_skills`, add to `summary` a field `missing_templates: [<skill>, ...]` and skip that skill's sections.
~~~

- [ ] **Step 3: Verify the file exists with the expected frontmatter**

Run: `test -f .claude/agents/upgrade-planner.md && echo OK`
Expected: `OK`.

Run: `grep -c "^name: upgrade-planner$" .claude/agents/upgrade-planner.md`
Expected: `1`.

Run: `grep -c "^model: opus$" .claude/agents/upgrade-planner.md`
Expected: `1`.

Run: `grep -E "^tools:.*\b(Write|Edit|NotebookEdit)\b" .claude/agents/upgrade-planner.md`
Expected: no output.

Run: `grep -c "^## " .claude/agents/upgrade-planner.md`
Expected: `>= 5`.

Run: `grep -c '^```upgrade-plan$' .claude/agents/upgrade-planner.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add .claude/agents/upgrade-planner.md
git commit -m "feat(agents): add upgrade-planner plugin-internal subagent"
```

---

## Task 3 — Document subagent authoring rules in `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (repo root)

- [ ] **Step 1: Verify current `CLAUDE.md` has the "Skill Authoring Rules" section**

Run: `grep -n "Skill Authoring Rules" CLAUDE.md`
Expected: returns a line number.

- [ ] **Step 2: Append a "Subagent Authoring Rules" subsection immediately after "Skill Authoring Rules"**

Use the Edit tool. Anchor on the last bullet of the "Skill Authoring Rules" section and insert the following block right after it (blank line separator before the new heading):

```markdown

## Subagent Authoring Rules

The plugin ships its own read-only subagents under `.claude/agents/<name>.md`. They are discovered by Claude Code convention — do NOT register them in `.claude-plugin/plugin.json`. Current catalog: `repo-scanner`, `upgrade-planner`. Adding a new subagent requires a spec update.

### File format

Each subagent has YAML frontmatter and a Markdown body:

```
---
name: <kebab-case-name, matches filename>
description: <one sentence, include "read-only" if applicable>
tools: <comma-separated whitelist — required>
model: opus
---

# <Human-readable name>

## Role
## Inputs
## Output Contract
## Constraints
## Failure Mode
```

The five body sections are mandatory. The Output Contract section MUST include at least one fenced code block showing the exact reply shape (not placeholders like `<output>`).

### Tool-set policy

- Plugin subagents are **read-only** by default. Do not include `Write`, `Edit`, or `NotebookEdit` in the `tools:` frontmatter.
- `Bash` is permitted for read-only operations (`find`, `ls`, `wc`, `git ls-files`). The body prompt MUST forbid destructive bash explicitly (no `rm`, `mv`, `cp`, redirects into project files, git state changes).
- Any write-capable subagent requires its own spec with a tool-set carve-out.

### Invocation pattern (for consumer skills)

Consumer skills dispatch via the Agent tool. Example:

```
Use the Agent tool with:
  subagent_type: repo-scanner
  description: "Scan the current project for use-case signals"
  prompt: |
    Scan the project rooted at the current working directory.
    Return your standard `repo-scan` fenced block.
```

Consumers parse the contracted fenced block from the reply and validate every expected field. If the parse fails, the consumer MUST fall back to its previous inline behavior, not proceed with partial data.

### Forbidden patterns

- Subagents dispatching other subagents — nested dispatch blows up context budgets.
- Subagents writing user files — reserved for a future spec.
- Consumer skills invoking subagents without parsing the contracted output — "run it and hope" is not acceptable.
```

- [ ] **Step 3: Verify the section was added**

Run: `grep -c "Subagent Authoring Rules" CLAUDE.md`
Expected: `1`.

Run: `grep -c "subagent_type: repo-scanner" CLAUDE.md`
Expected: `1` (the invocation example).

Run: `grep -c "repo-scanner" CLAUDE.md`
Expected: `>= 2` (catalog mention + invocation example).

Run: `grep -c "upgrade-planner" CLAUDE.md`
Expected: `>= 1` (catalog mention).

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): add subagent authoring rules"
```

---

## Task 4 — Verification

This task has no commit. It is the final gate before the PR is opened.

- [ ] **Step 1: Static grep — subagent files exist with correct frontmatter**

Run:
```bash
test -f .claude/agents/repo-scanner.md && test -f .claude/agents/upgrade-planner.md && echo OK
```
Expected: `OK`.

Run:
```bash
grep -l "^model: opus$" .claude/agents/repo-scanner.md .claude/agents/upgrade-planner.md
```
Expected: both files listed.

- [ ] **Step 2: Static grep — tool-set is read-only**

Run:
```bash
grep -E "^tools:.*\b(Write|Edit|NotebookEdit)\b" .claude/agents/repo-scanner.md .claude/agents/upgrade-planner.md
```
Expected: no output.

- [ ] **Step 3: Static grep — body structure is complete**

Run:
```bash
grep -c "^## " .claude/agents/repo-scanner.md
grep -c "^## " .claude/agents/upgrade-planner.md
```
Expected: each `>= 5`.

Run:
```bash
grep -c '^```repo-scan$' .claude/agents/repo-scanner.md
grep -c '^```upgrade-plan$' .claude/agents/upgrade-planner.md
```
Expected: each `1`.

- [ ] **Step 4: Static grep — authoring docs landed**

Run:
```bash
grep -c "Subagent Authoring Rules" CLAUDE.md
```
Expected: `1`.

- [ ] **Step 5: Static grep — manifest is unchanged**

Run:
```bash
git diff --stat origin/main -- .claude-plugin/plugin.json
```
Expected: no output (the manifest was not modified by this branch).

- [ ] **Step 6: Static grep — no consumer wiring leaked in**

Run:
```bash
grep -l "subagent_type: repo-scanner" skills/*/SKILL.md 2>/dev/null
grep -l "subagent_type: upgrade-planner" skills/*/SKILL.md 2>/dev/null
```
Expected: both commands return no output. Consumer wiring is Initiative #7 (onboarding) and a separate upgrade follow-up — not this initiative.

- [ ] **Step 7: Manual sanity check — subagent dispatch**

In a Claude Code session running inside this repo:

1. Invoke the Agent tool with `subagent_type: repo-scanner` and the prompt `"Scan the project rooted at the current working directory. Return your standard repo-scan block."`. Verify the reply contains exactly one fenced `repo-scan` block with all contracted fields (`inferred_use_case`, `signals`, `graphify_candidate`, `existing_claude_md`, `existing_agents_md`, `repo_size_bucket`).
2. Invoke the Agent tool with `subagent_type: upgrade-planner` on a fixture project containing at least one attributed delimited section in `CLAUDE.md`. Pass a minimal `canonical_templates` mapping inline via the prompt. Verify the reply contains exactly one fenced `upgrade-plan` block with a `proposed_changes` list and a `summary` object.

Document the result in the PR description (terminal paste or screenshot).

- [ ] **Step 8: Cross-check spec Success Criteria**

Open `docs/superpowers/specs/2026-04-21-plugin-internal-subagents-design.md` and tick every bullet in the "Success Criteria" section against the current state of the branch. Any unmet criterion blocks the PR.

- [ ] **Step 9: Open PR**

```bash
gh pr create --title "Plugin-internal subagents: repo-scanner, upgrade-planner" --body "$(cat <<'EOF'
## Summary

- Ship two plugin-internal read-only subagents (`repo-scanner`, `upgrade-planner`) under `.claude/agents/`
- Add "Subagent Authoring Rules" section to the plugin's `CLAUDE.md`
- No consumer wiring — that is tracked in Initiative #7 (onboarding refactor) and a separate upgrade follow-up

## Spec

`docs/superpowers/specs/2026-04-21-plugin-internal-subagents-design.md`

## Test plan

- [x] Static grep: both subagent files exist with `name:`, `tools:`, `model: opus`
- [x] Static grep: tool-set is read-only (no Write/Edit/NotebookEdit)
- [x] Static grep: body has all five mandatory sections and a concrete output-contract fence
- [x] Static grep: `CLAUDE.md` has "Subagent Authoring Rules"
- [x] Static grep: `.claude-plugin/plugin.json` untouched
- [x] Static grep: no skill references `subagent_type: repo-scanner` or `subagent_type: upgrade-planner`
- [x] Manual: Agent-tool dispatch returns a well-formed fenced block for both subagents

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review (performed at plan authoring time)

- **Spec coverage:** Every Success Criterion in the spec maps to a task. Subagent files exist → Tasks 1/2 Step 3. Frontmatter shape → Tasks 1/2 Step 4. Read-only tool-set → Task 4 Step 2. Body structure → Task 4 Step 3. Output contract → Task 4 Step 3 (fenced-block grep). Authoring docs → Task 3. Manifest unchanged → Task 4 Step 5. No consumer wiring → Task 4 Step 6. Manual sanity check → Task 4 Step 7.
- **Placeholders:** No "TBD", "similar to Task N", or unspecified steps. Each file-creation task embeds the full subagent body verbatim.
- **Type consistency:** Subagent names `repo-scanner` and `upgrade-planner` match across spec, both subagent bodies, the CLAUDE.md authoring block, and every verification grep. Tool-set `Bash, Glob, Grep, Read` is identical in both frontmatters.
- **Known soft edge:** Task 4 Step 7 requires a live Claude Code session to run the manual dispatch check — it cannot be scripted. This is acceptable because the output contract itself is grep-verifiable at file level; the manual check only confirms Claude Code actually picks up the subagent from `.claude/agents/`.
