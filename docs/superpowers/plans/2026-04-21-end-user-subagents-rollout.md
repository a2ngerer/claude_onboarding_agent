# End-User Subagents Rollout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the subagent-generation pattern from `knowledge-base-builder` to four additional setup skills (`coding-setup`, `web-development-setup`, `data-science-setup`, `academic-writing-setup`) via a shared helper, an opt-in prompt, a collision-skip policy, and a metadata update.

**Architecture:** Markdown-only refactor of existing SKILL.md files plus one new shared helper (`skills/_shared/emit-subagent.md`). Collision handling, opt-in prompt, and metadata merge are centralized in the helper; skills reference it from their post-context-questions step. No executable code.

**Tech Stack:** Markdown, Claude Code skill framework. Verification is grep-based plus a documented manual E2E walkthrough.

**Spec:** `docs/superpowers/specs/2026-04-21-end-user-subagents-rollout-design.md` — read it first. Every task below references decisions made there.

---

## Conventions for this plan

- Commit messages follow the existing repo style (`feat(scope):`, `refactor(scope):`, `docs(scope):`, `chore(scope):`). One commit per task.
- "Test" for markdown refactor = `grep` before and after. "Passing test" = grep confirms the new content and the absence of rejected patterns.
- **Never** use `git commit --no-verify`. If a pre-commit hook fails, fix the underlying issue.
- Language for all committed artifacts: English.
- Subagent slug, frontmatter `name:`, and filename MUST be identical across every reference. The canonical slugs are: `code-reviewer`, `component-auditor`, `notebook-auditor`, `writing-style-auditor`. (The existing `obsidian-vault-keeper` is untouched by this plan.)

## File Structure

**New:**
- `skills/_shared/emit-subagent.md` — shared opt-in + emit + collision-check + meta-update procedure

**Modified:**
- `skills/coding-setup/SKILL.md` — add emit step for `code-reviewer`
- `skills/web-development-setup/SKILL.md` — add emit step for `component-auditor`
- `skills/data-science-setup/SKILL.md` — add emit step for `notebook-auditor`
- `skills/academic-writing-setup/SKILL.md` — add emit step for `writing-style-auditor`
- `skills/_shared/write-meta.md` — merge `subagents_installed` as a union across runs
- `skills/checkup/SKILL.md` — include `.claude/agents/<slug>.md` in detection and `--rebuild` preview
- `skills/upgrade/SKILL.md` — include `.claude/agents/<slug>.md` in dry-run preview
- `CLAUDE.md` (repo root) — add subagent-authoring rules under "Skill Authoring Rules"
- `README.md` (if it documents what skills generate)

**Untouched:**
- `skills/knowledge-base-builder/SKILL.md` — already follows the pattern, no rewrite required.
- All non-catalog skills (`devops-setup`, `office-setup`, `content-creator-setup`, `research-setup`, `design-setup`, `graphify-setup`, `onboarding`, `tipps`).

---

## Task 1 — Foundation: Authoring Rules in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (repo root)

- [ ] **Step 1: Verify current CLAUDE.md has the "Skill Authoring Rules" section**

Run: `grep -n "Skill Authoring Rules" CLAUDE.md`
Expected: Returns a line number.

- [ ] **Step 2: Append a "Subagent Emission" subsection under "Skill Authoring Rules"**

Insert the following block immediately before the closing of the "Skill Authoring Rules" section (use the Edit tool; anchor on the last bullet in that section):

```markdown

## Subagent Emission (End-User Subagents)

When a setup skill generates a project-local subagent (`.claude/agents/<slug>.md`), apply these rules:

**Catalog (v1 — plugin-owned filenames):**

| Slug | Owning Skill | Tools |
|---|---|---|
| `code-reviewer` | coding-setup | Bash, Read, Grep, Glob |
| `component-auditor` | web-development-setup | Read, Grep, Glob |
| `notebook-auditor` | data-science-setup | Read, Grep, Glob, Bash |
| `writing-style-auditor` | academic-writing-setup | Read, Grep, Glob |
| `obsidian-vault-keeper` | knowledge-base-builder | Bash, Read, Glob, Grep |

**Topic exclusivity:** Each slug has exactly one owning skill. Two skills never write the same filename. Adding a new subagent requires a spec update, not an ad-hoc skill change.

**Opt-in:** Except for `obsidian-vault-keeper` (gated on Obsidian-CLI availability), every emission is preceded by an opt-in prompt. See `skills/_shared/emit-subagent.md` for the canonical prompt.

**Collision policy:** Skip the write if the target file already exists; log `Skipped .claude/agents/<slug>.md (already exists)`. Explicit regeneration is only via `checkup --rebuild` or `upgrade`.

**Description rules:** The frontmatter `description:` field starts with `Use to …` or `Use when …`, names concrete trigger phrases, and stays under three sentences. Filenames are kebab-case, noun-led, and never prefixed by the owning skill.

**File ownership:** The plugin owns only the filenames in the catalog above. Any other file in `.claude/agents/` is user-authored and never touched.
```

- [ ] **Step 3: Verify the section was added**

Run: `grep -c "Subagent Emission" CLAUDE.md`
Expected: `1`

Run: `grep -c "code-reviewer" CLAUDE.md`
Expected: `1` (the row in the table)

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): add end-user subagent emission rules and catalog"
```

---

## Task 2 — Shared Helper: `skills/_shared/emit-subagent.md`

**Files:**
- Create: `skills/_shared/emit-subagent.md`

- [ ] **Step 1: Verify the target path is currently empty**

Run: `test -f skills/_shared/emit-subagent.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create `skills/_shared/emit-subagent.md` with the following content**

```markdown
# Emit End-User Subagent

Shared procedure consumed by setup skills that offer to generate a project-local subagent under `.claude/agents/<slug>.md`. Read before the skill's artifact-generation step.

## Inputs (required)

The calling skill passes these values when invoking the procedure:

- `slug` — kebab-case filename stem, e.g. `code-reviewer`
- `purpose_blurb` — one-sentence natural-language description of what the subagent does ("Review a PR-sized diff against project conventions.")
- `frontmatter_description` — the exact string to place in the subagent's `description:` field
- `tools_list` — comma-separated string, e.g. `Bash, Read, Grep, Glob`
- `body_markdown` — the subagent's prompt body (everything after the frontmatter)
- `rules_files` — zero or more `.claude/rules/*.md` filenames the subagent should read on dispatch (may be empty)

## Step 1 — Opt-in prompt

Ask the user exactly once (adapt to detected language; keep the slug and file path in English):

```
This skill can generate a project-local subagent (`<slug>`) that Claude
auto-dispatches when the conversation matches its description. The
subagent lives in .claude/agents/<slug>.md and only loads when invoked —
no always-on context cost.

Purpose: <purpose_blurb>

Install <slug> now? (yes / no / later)
```

- **yes** → set `emit_subagent: true`, continue to Step 2.
- **no** → set `emit_subagent: false`, skip to Step 6 (completion-summary hint only).
- **later** → treat as `no` for v1. Set `emit_subagent: false`, `subagent_deferred: true`. Skip to Step 6.

## Step 2 — Collision check

Before writing, check if `.claude/agents/<slug>.md` already exists:

```
test -f .claude/agents/<slug>.md && echo EXISTS || echo MISSING
```

- If `EXISTS`: log `Skipped .claude/agents/<slug>.md (already exists)`, set `subagent_skipped_existing: true`, and skip to Step 5 (metadata update still runs — the file is on disk and should be recorded).
- If `MISSING`: continue to Step 3.

## Step 3 — Ensure target directory and assemble content

1. Run `mkdir -p .claude/agents`.
2. Assemble the file content from this template:

```markdown
---
name: <slug>
description: <frontmatter_description>
tools: <tools_list>
---

<body_markdown>

## Before your first action
1. Read `CLAUDE.md` (project root) for project context.
2. Read the rules files relevant to your scope: <rules_files> (or: none).
3. If a listed rules file is missing, say so in your response header and proceed with best-effort defaults — do not stop.
```

Substitute every angle-bracket placeholder with the value passed by the calling skill. If `rules_files` is empty, write the literal string `none` on line 2 of that section.

## Step 4 — Write

Write the assembled content to `.claude/agents/<slug>.md` using the Write tool.

## Step 5 — Metadata update

Append `<slug>` to the `subagents_installed[]` array in `./.claude/onboarding-meta.json` via `skills/_shared/write-meta.md` (which merges as a union across runs). If the meta file does not yet exist, the calling skill's normal write-meta invocation creates it with `subagents_installed: ["<slug>"]`.

## Step 6 — Completion-summary hint

Regardless of the branch taken, the calling skill's completion summary includes one of these lines:

- `yes` path: `.claude/agents/<slug>.md                 — project-local subagent (auto-invoked)`
- `yes` path, collision skipped: `.claude/agents/<slug>.md (already existed — skipped; re-run /checkup --rebuild to regenerate)`
- `no` / `later` path: `Subagent <slug> not installed — re-run the skill to add it later.`

## Rules for the calling skill

- Call this procedure **after** context questions and the Obsidian-style system-check step (if any), **before** generating CLAUDE.md and other artifacts. Subagent installation is a lightweight file write and does not depend on the rest of the artifact generation.
- Do **not** embed the opt-in prompt text inline in the SKILL.md — read this helper and follow it. Keeps prompts consistent across skills.
- Do **not** vary the collision policy. Skip-on-exists is the contract; regeneration is `checkup --rebuild` territory.
```

- [ ] **Step 3: Verify file exists and references the catalog slugs**

Run: `test -f skills/_shared/emit-subagent.md && echo OK`
Expected: `OK`

Run: `grep -c "code-reviewer\|component-auditor\|notebook-auditor\|writing-style-auditor" skills/_shared/emit-subagent.md`
Expected: `0` — the helper is generic; slugs only appear in caller skills and in CLAUDE.md's catalog table. Any hit here means the helper was hardcoded to one caller and must be generalized.

- [ ] **Step 4: Commit**

```bash
git add skills/_shared/emit-subagent.md
git commit -m "feat(shared): add emit-subagent helper for end-user subagent generation"
```

---

## Task 3 — `skills/_shared/write-meta.md` — merge `subagents_installed`

**Files:**
- Modify: `skills/_shared/write-meta.md`

- [ ] **Step 1: Read the current helper to locate the merge logic**

Use the Read tool on `skills/_shared/write-meta.md`. Identify where `skills_used` is merged as a union across runs — the same treatment must be applied to the new `subagents_installed` field.

- [ ] **Step 2: Add `subagents_installed` to the merge logic**

Edit `skills/_shared/write-meta.md` so that when the meta file already exists, `subagents_installed` from the prior file is unioned with any new slug passed in (dedupe, preserve order). If the prior file has no `subagents_installed` key, initialize it as an empty array before unioning.

Document the schema addition in the helper's "Schema" (or equivalent) section with the line:

```
- subagents_installed: string[] — slugs of project-local subagents installed by the plugin (e.g., "code-reviewer", "component-auditor"). Union-merged across runs.
```

- [ ] **Step 3: Verify**

Run: `grep -c "subagents_installed" skills/_shared/write-meta.md`
Expected: at least `2` (schema line + merge rule).

- [ ] **Step 4: Commit**

```bash
git add skills/_shared/write-meta.md
git commit -m "feat(shared): union-merge subagents_installed in onboarding-meta.json"
```

---

## Task 4 — `coding-setup`: emit `code-reviewer`

**Files:**
- Modify: `skills/coding-setup/SKILL.md`

- [ ] **Step 1: Locate the right insertion point**

Read `skills/coding-setup/SKILL.md`. The emit step must sit **after** the context questions (Step 2 in the skill) and **before** artifact generation (Step 3). If Step numbers differ, insert between the final context-question step and the artifact-generation step.

- [ ] **Step 2: Insert the emit step**

Add a new step (renumber subsequent steps if necessary) with this content:

```markdown
## Step <N>: Offer Project-Local Subagent

Read `skills/_shared/emit-subagent.md` and follow it with these inputs:

- `slug`: `code-reviewer`
- `purpose_blurb`: "Review a PR-sized diff (uncommitted, staged, or a named commit range) against the project's code standards."
- `frontmatter_description`: "Use to review uncommitted diffs, staged changes, or a named commit range against the project's code standards and conventions. Dispatch when the user asks for a code review, wants feedback on a change, or says 'review this' / 'check my changes' / 'review my diff'."
- `tools_list`: `Bash, Read, Grep, Glob`
- `rules_files`: (none — this subagent relies on CLAUDE.md's code standards)
- `body_markdown`:

  ```
  You are the Code Reviewer. You review a bounded diff against the project's code standards and conventions documented in CLAUDE.md.

  ## Procedure
  1. Determine the diff scope from the caller's request (uncommitted changes, staged only, a named commit range, or a specific file list). If ambiguous, ask once; otherwise proceed with `git diff` on uncommitted + staged.
  2. Read CLAUDE.md for project context and standards.
  3. Review the diff. Flag: YAGNI violations, speculative abstractions, missing validation at boundaries, error-handling for impossible scenarios, test coverage gaps, convention drift.
  4. Return a structured verdict: one-line summary, bullet list of findings (severity: blocker / suggestion / nit), and a final recommendation (ship / revise / block).

  ## Rules
  - Do not write code. Your output is feedback, not a fix.
  - Do not run tests or linters on the caller's behalf unless explicitly asked.
  - Cite file:line for every finding.
  ```
```

- [ ] **Step 3: Update the completion summary**

In the skill's Step 6 (Completion Summary, or equivalent), add a line under "Files created" that references `.claude/agents/code-reviewer.md` conditional on the emit result (use the three-branch hint from `emit-subagent.md` Step 6).

- [ ] **Step 4: Verify**

Run: `grep -c "code-reviewer" skills/coding-setup/SKILL.md`
Expected: at least `2` (slug field + completion-summary line).

Run: `grep -c "_shared/emit-subagent.md" skills/coding-setup/SKILL.md`
Expected: `1`.

- [ ] **Step 5: Commit**

```bash
git add skills/coding-setup/SKILL.md
git commit -m "feat(coding-setup): emit code-reviewer subagent (opt-in)"
```

---

## Task 5 — `web-development-setup`: emit `component-auditor`

**Files:**
- Modify: `skills/web-development-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

Read `skills/web-development-setup/SKILL.md`. Insert between the last context-question step and the artifact-generation step.

- [ ] **Step 2: Insert the emit step**

```markdown
## Step <N>: Offer Project-Local Subagent

Read `skills/_shared/emit-subagent.md` and follow it with these inputs:

- `slug`: `component-auditor`
- `purpose_blurb`: "Audit a component or an API route against the project's structure, routing, and naming conventions."
- `frontmatter_description`: "Use to audit a React/Vue/Svelte component or an API route for the project's structure, routing, and naming conventions. Dispatch when the user asks 'does this component match our conventions', 'audit this route', or 'review this component'."
- `tools_list`: `Read, Grep, Glob`
- `rules_files`: `.claude/rules/component-structure.md, .claude/rules/api-conventions.md`
- `body_markdown`:

  ```
  You are the Component Auditor. You audit a component file or an API route against the project's conventions.

  ## Procedure
  1. Identify the target file(s) from the caller's request.
  2. Read the relevant rules files (component-structure.md for UI, api-conventions.md for routes).
  3. Audit the target for: file location, naming, exports, prop/signature shape, colocation of styles/tests, routing convention, error-shape for APIs.
  4. Return a structured verdict: target file(s), findings (severity: blocker / suggestion / nit) with file:line, recommended fixes (describe, do not apply).

  ## Rules
  - Do not write code. Describe fixes; do not apply them.
  - If a rules file is missing, say so in your header and audit against the framework's idiomatic defaults.
  ```
```

- [ ] **Step 3: Update completion summary.** Add the conditional `.claude/agents/component-auditor.md` line.

- [ ] **Step 4: Verify**

Run: `grep -c "component-auditor" skills/web-development-setup/SKILL.md`
Expected: at least `2`.

Run: `grep -c "_shared/emit-subagent.md" skills/web-development-setup/SKILL.md`
Expected: `1`.

- [ ] **Step 5: Commit**

```bash
git add skills/web-development-setup/SKILL.md
git commit -m "feat(web-development-setup): emit component-auditor subagent (opt-in)"
```

---

## Task 6 — `data-science-setup`: emit `notebook-auditor`

**Files:**
- Modify: `skills/data-science-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

Read `skills/data-science-setup/SKILL.md`. Insert between the last context-question step and artifact generation.

- [ ] **Step 2: Insert the emit step**

```markdown
## Step <N>: Offer Project-Local Subagent

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
```

- [ ] **Step 3: Update completion summary.** Add the conditional `.claude/agents/notebook-auditor.md` line.

- [ ] **Step 4: Verify**

Run: `grep -c "notebook-auditor" skills/data-science-setup/SKILL.md`
Expected: at least `2`.

Run: `grep -c "_shared/emit-subagent.md" skills/data-science-setup/SKILL.md`
Expected: `1`.

- [ ] **Step 5: Commit**

```bash
git add skills/data-science-setup/SKILL.md
git commit -m "feat(data-science-setup): emit notebook-auditor subagent (opt-in)"
```

---

## Task 7 — `academic-writing-setup`: emit `writing-style-auditor`

**Files:**
- Modify: `skills/academic-writing-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

Read `skills/academic-writing-setup/SKILL.md`. Insert between the last context-question step and artifact generation.

- [ ] **Step 2: Insert the emit step**

```markdown
## Step <N>: Offer Project-Local Subagent

Read `skills/_shared/emit-subagent.md` and follow it with these inputs:

- `slug`: `writing-style-auditor`
- `purpose_blurb`: "Audit an academic passage for voice, tense, structure, and citation hygiene against the project's rules."
- `frontmatter_description`: "Use to audit an academic passage (paragraph, section, or chapter draft) for voice, tense, section-structure compliance, and citation hygiene against the project's writing-style and citation rules. Dispatch when the user asks to review a paragraph, check style, verify citations, or 'audit this section'."
- `tools_list`: `Read, Grep, Glob`
- `rules_files`: `.claude/rules/writing-style.md, .claude/rules/citation-rules.md`
- `body_markdown`:

  ```
  You are the Writing Style Auditor. You audit academic prose against the project's writing-style and citation rules.

  ## Procedure
  1. Identify the target passage (paragraph, section, or file).
  2. Read writing-style.md (voice, tense, section rules) and citation-rules.md (.bib conventions, no-invented-citations).
  3. Audit for: first-person violations if passive is required, tense drift, banned AI-slop patterns, missing or malformed citations, invented citation keys, overlong sentences if the style file prescribes a limit.
  4. Return a structured verdict: target passage, findings with line reference and severity, concrete rewrite suggestions (describe, do not apply).

  ## Rules
  - Do not rewrite the passage. Describe the fix; let the caller apply it.
  - Never invent a citation to fill a gap — flag the gap instead.
  - If a rules file is missing, audit against general academic conventions and say so in the header.
  ```
```

- [ ] **Step 3: Update completion summary.** Add the conditional `.claude/agents/writing-style-auditor.md` line.

- [ ] **Step 4: Verify**

Run: `grep -c "writing-style-auditor" skills/academic-writing-setup/SKILL.md`
Expected: at least `2`.

Run: `grep -c "_shared/emit-subagent.md" skills/academic-writing-setup/SKILL.md`
Expected: `1`.

- [ ] **Step 5: Commit**

```bash
git add skills/academic-writing-setup/SKILL.md
git commit -m "feat(academic-writing-setup): emit writing-style-auditor subagent (opt-in)"
```

---

## Task 8 — `checkup` and `upgrade`: include subagent files in detection and preview

**Files:**
- Modify: `skills/checkup/SKILL.md`
- Modify: `skills/upgrade/SKILL.md`

- [ ] **Step 1: Read both skills to locate the artifact-inventory logic**

Use the Read tool on each file. Identify the section(s) where the skill enumerates plugin-generated files (CLAUDE.md markers, `.claude/rules/*.md`, `.gitignore` blocks). The subagent catalog must join that enumeration.

- [ ] **Step 2: Add a "Project-local subagents" subsection to `checkup/SKILL.md`**

Insert:

```markdown
### Project-Local Subagents

The plugin owns these subagent filenames under `.claude/agents/`:

| Slug | Owning Skill |
|---|---|
| `code-reviewer` | coding-setup |
| `component-auditor` | web-development-setup |
| `notebook-auditor` | data-science-setup |
| `writing-style-auditor` | academic-writing-setup |
| `obsidian-vault-keeper` | knowledge-base-builder |

Detection: read `.claude/onboarding-meta.json` and list the slugs in `subagents_installed[]`. Cross-check against `.claude/agents/` on disk.

`--rebuild` behaviour:
- For each slug in the catalog, if the owning skill was run (per `skills_used`) and the subagent file is either missing or present-but-plugin-owned, include it in the rebuild preview.
- Any file in `.claude/agents/` not on the catalog is user-authored and never touched.
- Rebuild re-runs the owning skill's emit step via the shared helper; collision-skip is bypassed by the explicit preview confirmation.
```

- [ ] **Step 3: Add the equivalent block to `upgrade/SKILL.md`**

Insert a near-identical block under the upgrade skill's scan/preview section. Upgrade does not rebuild by default — it reports drift (expected-vs-actual) and emits the subagent only if a new plugin version has introduced a new slug the project's `skills_used` would trigger.

- [ ] **Step 4: Verify**

Run: `grep -c "Project-Local Subagents" skills/checkup/SKILL.md`
Expected: `1`.

Run: `grep -c "Project-Local Subagents" skills/upgrade/SKILL.md`
Expected: `1`.

Run: `grep -c "code-reviewer" skills/checkup/SKILL.md`
Expected: at least `1`.

- [ ] **Step 5: Commit**

```bash
git add skills/checkup/SKILL.md skills/upgrade/SKILL.md
git commit -m "feat(checkup,upgrade): include project-local subagents in detection and preview"
```

---

## Task 9 — Deduplication + Collision verification task

This task has no commit. It confirms deduplication and collision policy end-to-end before the verification task.

- [ ] **Step 1: Create a scratch project with two setups worth of subagents**

```bash
mkdir -p /tmp/subagents-dedup-test
cd /tmp/subagents-dedup-test
git init -q
```

- [ ] **Step 2: Run `/coding-setup`, accept the subagent prompt**

Expected: `.claude/agents/code-reviewer.md` exists; `.claude/onboarding-meta.json` contains `"subagents_installed": ["code-reviewer"]`.

- [ ] **Step 3: Re-run `/coding-setup`, accept the prompt again**

Expected: emit step logs `Skipped .claude/agents/code-reviewer.md (already exists)`; file mtime unchanged; meta's `subagents_installed[]` still `["code-reviewer"]` (union merge, no duplication).

- [ ] **Step 4: Run `/web-development-setup`, accept the prompt**

Expected: `.claude/agents/component-auditor.md` exists alongside `code-reviewer.md`; meta's `subagents_installed[]` becomes `["code-reviewer", "component-auditor"]`.

- [ ] **Step 5: Create a user-authored file and confirm it is untouched**

```bash
cat > .claude/agents/my-custom-agent.md <<EOF
---
name: my-custom-agent
description: My own thing.
tools: Read
---
User-authored.
EOF
CUSTOM_MTIME=$(stat -f '%m' .claude/agents/my-custom-agent.md)
```

Run `/checkup --rebuild`, confirm its dry-run preview does NOT list `my-custom-agent.md`. After rebuild: `stat -f '%m' .claude/agents/my-custom-agent.md` returns the unchanged `$CUSTOM_MTIME`.

---

## Task 10 — Verification

No commit. Final gate before PR.

- [ ] **Step 1: Static grep — generator skills reference the helper**

Run:
```bash
grep -l "_shared/emit-subagent.md" skills/coding-setup/SKILL.md skills/web-development-setup/SKILL.md skills/data-science-setup/SKILL.md skills/academic-writing-setup/SKILL.md
```
Expected: all four paths appear.

- [ ] **Step 2: Static grep — rejected skills do NOT emit subagents**

Run:
```bash
grep -l "_shared/emit-subagent.md" skills/devops-setup/SKILL.md skills/office-setup/SKILL.md skills/content-creator-setup/SKILL.md skills/research-setup/SKILL.md skills/design-setup/SKILL.md skills/graphify-setup/SKILL.md
```
Expected: no output (no rejected skill references the helper).

Run:
```bash
grep -l "\.claude/agents/" skills/devops-setup/SKILL.md skills/office-setup/SKILL.md skills/content-creator-setup/SKILL.md skills/research-setup/SKILL.md skills/design-setup/SKILL.md skills/graphify-setup/SKILL.md
```
Expected: no output.

- [ ] **Step 3: Static grep — CLAUDE.md has the subagent catalog**

Run: `grep -c "Subagent Emission" CLAUDE.md`
Expected: `1`.

Run: `grep -c "code-reviewer\|component-auditor\|notebook-auditor\|writing-style-auditor\|obsidian-vault-keeper" CLAUDE.md`
Expected: at least `5` (one per slug in the catalog table).

- [ ] **Step 4: Static grep — helper is generic**

Run: `grep -c "code-reviewer\|component-auditor\|notebook-auditor\|writing-style-auditor" skills/_shared/emit-subagent.md`
Expected: `0`.

- [ ] **Step 5: Manual E2E walkthrough**

Run Task 9 end-to-end. Document the result in the PR description.

- [ ] **Step 6: Cross-check spec Success Criteria**

Open `docs/superpowers/specs/2026-04-21-end-user-subagents-rollout-design.md` and tick every bullet in "Success Criteria" against the current branch. Any unmet criterion blocks the PR.

- [ ] **Step 7: Open PR**

```bash
gh pr create --title "End-user subagents: broad rollout across setup skills" --body "$(cat <<'EOF'
## Summary

- Extend the subagent-generation pattern from knowledge-base-builder to coding-setup, web-development-setup, data-science-setup, academic-writing-setup
- Add shared helper `skills/_shared/emit-subagent.md` (opt-in prompt, collision-skip, metadata update)
- Lock subagent catalog + file-ownership rules into CLAUDE.md

## Spec

`docs/superpowers/specs/2026-04-21-end-user-subagents-rollout-design.md`

## Test plan

- [x] Static grep: four generators reference the helper; six rejected skills do not
- [x] Static grep: CLAUDE.md contains the catalog
- [x] Manual E2E: dedup across multi-setup projects + user-file ownership
- [x] Manual E2E: collision skip on re-run preserves mtime

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review (performed at plan authoring time)

- **Spec coverage:** Every Success Criterion in the spec maps to a task. Opt-in prompt + emit → Task 2 (helper) + Tasks 4–7 (per-skill). Collision skip → Task 2 Step 2 + Task 9 Step 3. Dedup across multi-setup → Task 9 Step 4. Metadata recording → Task 3. File-ownership boundary → Task 9 Step 5. Shared helper in place → Task 2 + Task 10 Step 1. Rejected candidates stay rejected → Task 10 Step 2.
- **Placeholders:** The step-number placeholder `<N>` in Tasks 4–7 is deliberate — each skill has a different step count, so the implementer renumbers at integration time. All other values (slugs, descriptions, tools, file paths) are literal.
- **Type consistency:** Helper filename `skills/_shared/emit-subagent.md` is referenced identically in Tasks 2, 4, 5, 6, 7, 10. Subagent slugs (`code-reviewer`, `component-auditor`, `notebook-auditor`, `writing-style-auditor`) match across spec, helper-free verification step, CLAUDE.md catalog, and per-skill insert blocks.
- **Cross-initiative dependencies:** The per-skill `rules_files` references (e.g., `.claude/rules/component-structure.md`) assume Initiative #5 has landed. If this plan is executed before #5 merges, the `writing-style-auditor`, `component-auditor`, and `notebook-auditor` will run against the legacy `claude_instructions/` path — the shared helper's "if missing, proceed with best-effort defaults" branch handles that gracefully, but the dependency is real. Merge order: #5 before this plan's Tasks 5–7 ideally.
- **Known soft edges:** The `later` branch in the opt-in prompt currently behaves identically to `no`. That is intentional for v1 (a dedicated `--add-subagent` command is out of scope) and documented in the spec.
