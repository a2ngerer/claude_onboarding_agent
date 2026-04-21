# Onboarding Subagent Orchestration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the `onboarding` orchestrator to dispatch plugin-internal subagents (`repo-scanner`, `artifact-verifier`, `audit-collector`) for evidence-heavy phases, keeping only routing and cross-phase state in the main context. Optionally mirror the pattern in `checkup` and `upgrade` as a Wave 2 follow-on.

**Architecture:** Markdown-based refactor of existing SKILL.md files. No new shared files. Each delegation point becomes an explicit Agent-tool dispatch block plus an inline fallback branch. The subagents themselves are defined by Initiative #1 — this plan treats them as an external contract.

**Tech Stack:** Markdown, Claude Code skill framework, Agent tool. Verification is grep-based (static) plus a manual E2E walkthrough.

**Spec:** `docs/superpowers/specs/2026-04-21-onboarding-subagent-orchestration-design.md` — read it first. Every task below references decisions made there.

**Hard dependency:** Initiative #1 (plugin-internal subagents) MUST ship before Task 2 of this plan begins. Task 1 is a gate that enforces this.

---

## Conventions for this plan

- Commit messages follow the existing repo style (`feat(scope):`, `refactor(scope):`, `docs(scope):`, `chore(scope):`). One commit per task (Tasks 1–3 are Wave 1; Tasks 4–5 are optional Wave 2).
- "Test" for markdown refactor = `grep` before and after. "Failing test" = grep shows the old content. "Passing test" = grep confirms the new content and the absence of the old.
- **Never** use `git commit --no-verify`. If a pre-commit hook fails, fix the underlying issue.
- Language for all committed artifacts: English (repo rule).

## File Structure

**Modified (Wave 1):**
- `skills/onboarding/SKILL.md` — refactor Step 2, add Step 5a (verify), add Step 7 (optional audit)

**Modified (Wave 2, optional):**
- `skills/checkup/SKILL.md` — delegate Stage 1.2 + Stage 3
- `skills/upgrade/SKILL.md` — delegate Pass 2.1

**Not modified:**
- The 11 setup skills (not orchestrators)
- `skills/tipps/SKILL.md` (wrapped by `audit-collector`, stays as-is)
- `skills/_shared/*` (no shared scaffolding change)

---

## Task 1 — Gate: Assert Initiative #1 Catalog Exists

**Files:** read-only check, no modifications.

This task is a hard gate. If it fails, **stop the plan** and resolve the Initiative #1 dependency before continuing.

- [ ] **Step 1: Locate the plugin-internal subagents catalog**

Expected location (per Initiative #1 design): one of
- `.claude-plugin/agents/` (directory of subagent definitions)
- `agents/` at the plugin repo root
- An index markdown: `docs/superpowers/specs/2026-04-21-plugin-internal-subagents-design.md`

Run:
```bash
test -d .claude-plugin/agents || test -d agents || test -f docs/superpowers/specs/2026-04-21-plugin-internal-subagents-design.md && echo CATALOG_PRESENT || echo CATALOG_MISSING
```

Expected: `CATALOG_PRESENT`. If `CATALOG_MISSING`, stop the plan and surface: "Initiative #1 has not shipped. This plan depends on the plugin-internal subagents catalog. Resolve #1 (or its equivalent tracking issue) before resuming."

- [ ] **Step 2: Confirm the three required subagent names exist**

Grep across the catalog location for the three names this plan consumes:

```bash
grep -rl "repo-scanner" .claude-plugin/agents/ agents/ 2>/dev/null
grep -rl "artifact-verifier" .claude-plugin/agents/ agents/ 2>/dev/null
grep -rl "audit-collector" .claude-plugin/agents/ agents/ 2>/dev/null
```

Expected: each grep returns at least one file. If any returns zero, stop — either the names drifted in Initiative #1 (update this plan's references before continuing) or the catalog is incomplete.

- [ ] **Step 3: Record the resolved catalog path**

Note the directory or file that contains the subagent definitions. Tasks 2–5 reference this path when constructing Agent-tool dispatch blocks.

- [ ] **Step 4: No commit**

This task writes nothing. It is a pre-condition check.

---

## Task 2 — Wave 1: Refactor `onboarding` Step 2 (Repo Scan)

**Files:**
- Modify: `skills/onboarding/SKILL.md`

- [ ] **Step 1: Read the current Step 2 block**

Use the Read tool on `skills/onboarding/SKILL.md`. Locate the `## Step 2: Scan the Repository` heading and its body (ends at the next `## Step` heading).

- [ ] **Step 2: Replace the body of Step 2 with a subagent dispatch block**

Use the Edit tool. The new body of Step 2 must contain:

1. A one-sentence intro that names the subagent.
2. An explicit dispatch block with the expected brief (inputs, expected output schema reference, token budget).
3. A parse step describing how the orchestrator extracts `inferred_use_case`, `graphify_candidate`, `existing_claude_md`, `existing_agents_md`, and `signals` from the returned report.
4. A `### Fallback` subsection containing the current inline-scan logic, to be used when the subagent times out, returns malformed output, or errors (per spec error-handling table).

Content template (adapt wording; keep technical fields identical):

```markdown
## Step 2: Scan the Repository (via `repo-scanner` subagent)

Dispatch a `repo-scanner` subagent (defined in the plugin subagent catalog — see Initiative #1) to gather repository signals without loading raw filesystem evidence into this context.

**Dispatch brief:**

```
Agent type: repo-scanner
Inputs:
  project_root: "./"
  signals_of_interest:
    - coding
    - web-development
    - data-science
    - academic-writing
    - knowledge-base
    - office
    - research
    - content-creator
    - devops
    - design
    - graphify
Expected output: structured report per catalog entry (cap: 500 tokens).
```

Parse the returned report. Extract:
- `inferred_use_case` → the use case for Step 3's option ordering
- `confidence` → displayed to the user only if `low`
- `graphify_candidate` → drives the Step 3 aside
- `existing_claude_md`, `existing_agents_md` → drive the Step 3 pre-notice
- `signals` → short list surfaced in the "inferred" option's explanation

### Fallback (if the subagent fails)

If the subagent times out once, returns malformed output twice in a row, or errors with a dispatch failure, print:

> "⚠ repo-scanner subagent unavailable — falling back to inline detection. Detection is best-effort; rerun `/onboarding` once the subagent is restored for full coverage."

Then run the inline heuristic (single source of truth — do not duplicate this list elsewhere in the SKILL):

- Count file extensions: `.py`, `.ts`, `.js`, `.go`, `.rs`, `.rb`, `.java`, `.cs` → coding signal
- Look for `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt` → strong coding signal
- Look for web-framework configs or entry points (`next.config.*`, `vite.config.*`, `astro.config.*`, `remix.config.*`, `svelte.config.*`, `nuxt.config.*`, `app/page.{tsx,jsx}`, `pages/` with `_app`/`index`, `src/routes/`, `index.html` next to `public/`, or framework deps in `package.json`) → web-development signal (dominates generic coding)
- Look for `.ipynb`, `notebooks/`, `data/raw/`, or DS deps (`pandas`/`polars`/`numpy`/`scikit-learn`/`torch`/`jax`) → data-science signal (dominates generic coding)
- Look for `.tex`, `.bib` → research signal
- Look for `sections/`, `bib/`, `main.tex`/`main.typ`, `.typ` alongside `.bib` → academic-writing signal (dominates generic research)
- Look for `*.docx`/`*.pptx`/`*.pdf`/`*.xlsx` → office signal
- Look for `notes/`, `vault/`, `wiki/`, `obsidian/` → knowledge-base signal
- Count source files and `.md`/`.pdf`/`.ipynb`; if > 1000 source files across 25+ languages OR > 100 PDFs/Markdown under `docs/`/`raw/`/`notes/`, set `graphify_candidate: true`
- Check `CLAUDE.md` and `AGENTS.md` existence

Produce the same shape the subagent would return, continue with Step 3.
```

Exact Edit operation:
- `old_string`: the current full body of `## Step 2: Scan the Repository` from the `## Step 2:` heading up to but not including `## Step 3: Present Options`.
- `new_string`: the content block above.

- [ ] **Step 3: Verify Step 2 now dispatches**

Run:
```bash
grep -c "repo-scanner" skills/onboarding/SKILL.md
```
Expected: ≥ 2 (at least one in the dispatch block, one in the fallback message).

Run:
```bash
grep -c "### Fallback" skills/onboarding/SKILL.md
```
Expected: ≥ 1 (will rise as Tasks 3 add more fallback blocks).

- [ ] **Step 4: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "refactor(onboarding): delegate Step 2 repo scan to repo-scanner subagent"
```

---

## Task 3 — Wave 1: Add Post-Dispatch Verification and Optional Audit

**Files:**
- Modify: `skills/onboarding/SKILL.md`

- [ ] **Step 1: Locate the insertion point — after Step 5 Dispatch, before Step 6**

Use the Read tool. Identify the section between `## Step 5: Dispatch` body and `## Step 6: Rebuild backup notice`.

- [ ] **Step 2: Insert Step 5a — Verify artifacts**

Insert the following block immediately after the last paragraph of Step 5 ("Step back completely. The setup skill handles everything from here. …") and before `## Step 6`:

```markdown
## Step 5a: Verify artifacts (via `artifact-verifier` subagent)

After the delegated setup skill reports completion, dispatch an `artifact-verifier` subagent to confirm the files it claimed to write exist and are structurally valid.

**Dispatch brief:**

```
Agent type: artifact-verifier
Inputs:
  files_to_check: [<paths the setup skill wrote — captured from its completion summary>]
Expected output: structured report per catalog entry (cap: 200 tokens).
```

Parse the report. If `status: ok`, print one line: `✓ Artifacts verified (<N> files checked).` If `status: issues`, print the issue list verbatim and suggest `/checkup` to decide next steps. Do NOT retry the setup skill automatically — the issues may be intentional (e.g. user skipped a file during the setup skill's own prompts).

### Fallback (if the subagent fails)

If the subagent fails per the spec error-handling table, print: `⚠ artifact-verifier unavailable — please spot-check the generated files manually.` Continue with Step 6.
```

- [ ] **Step 3: Insert Step 7 — Optional post-setup audit**

Insert this block after Step 6 (at the end of the file):

```markdown
## Step 7: Optional post-setup audit (via `audit-collector` subagent)

After all other steps complete, ask the user (adapt wording to detected language):

> "Run a post-setup audit now? It checks the new setup against current best practices without modifying anything. (y/n)"

If `y`, dispatch an `audit-collector` subagent.

**Dispatch brief:**

```
Agent type: audit-collector
Inputs:
  audit_skill: "tipps"
Expected output: structured report per catalog entry (cap: 300 tokens).
```

Parse `total`, `high`, `medium`, `low`, `top_titles`. Print a one-screen summary. If `high >= 1`, also suggest `/upgrade` to apply the recommended fixes.

If the user replies `n`, skip this step silently. Do not re-prompt within the session.

### Fallback (if the subagent fails)

If the subagent fails per the spec error-handling table, print: `⚠ audit-collector unavailable — run /tipps manually to audit the new setup.` End.
```

- [ ] **Step 4: Verify Wave 1 refactor is complete**

Run:
```bash
grep -c "repo-scanner\|artifact-verifier\|audit-collector" skills/onboarding/SKILL.md
```
Expected: ≥ 5 (dispatch blocks + fallback mentions across all three).

Run:
```bash
grep -c "### Fallback" skills/onboarding/SKILL.md
```
Expected: ≥ 3 (one per delegation point).

Run (ensures the old inline-scan code is no longer the Step 2 body):
```bash
awk '/^## Step 2:/,/^## Step 3:/' skills/onboarding/SKILL.md | grep -cE "^- Count file extensions|^- Look for .*\.ipynb files"
```
Expected: the inline-scan bullets appear only inside the `### Fallback` subsection, not as the primary path. Visual check: the `## Step 2` heading is immediately followed by the dispatch block, not the bullet list.

- [ ] **Step 5: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "feat(onboarding): add artifact verification and optional post-setup audit via subagents"
```

---

## Task 4 — Wave 2 (Optional): Mirror the Pattern in `checkup`

**Scope:** Optional follow-on. May ship in a separate PR. If included here, must pass the same grep assertions as Task 3.

**Files:**
- Modify: `skills/checkup/SKILL.md`

- [ ] **Step 1: Refactor Stage 1.2 (delimiter scan) to use `repo-scanner`**

Replace the inline `grep` pseudocode in Stage 1.2 with a `repo-scanner` dispatch. Brief inputs: `project_root: "./"`, `signals_of_interest: ["delimiters"]`. Expected output: a variant of the scan report with `delimiters_present: <true|false>` and `marker_files: [<paths>]`. Fallback: the current inline grep logic.

- [ ] **Step 2: Refactor Stage 3 (tipps invocation) to use `audit-collector`**

Replace the direct `/tipps` invocation in Stage 3 with an `audit-collector` dispatch. Brief inputs: `audit_skill: "tipps"`. Parse the same `{ total, high, medium, low, top_titles }` the current code already constructs. Fallback: direct `/tipps` invocation as today.

- [ ] **Step 3: Verify**

Run:
```bash
grep -c "repo-scanner\|audit-collector" skills/checkup/SKILL.md
```
Expected: ≥ 2.

Run:
```bash
grep -c "### Fallback\|Fallback (if" skills/checkup/SKILL.md
```
Expected: ≥ 2.

- [ ] **Step 4: Commit**

```bash
git add skills/checkup/SKILL.md
git commit -m "refactor(checkup): delegate delimiter scan and tipps audit to subagents"
```

---

## Task 5 — Wave 2 (Optional): Mirror the Pattern in `upgrade`

**Scope:** Optional follow-on. Same PR or separate.

**Files:**
- Modify: `skills/upgrade/SKILL.md`

- [ ] **Step 1: Refactor Pass 2.1 (enumerate candidate files) to use `repo-scanner`**

Replace the inline file-enumeration description in Pass 2.1 with a `repo-scanner` dispatch. Brief inputs: `project_root: "./"`, `signals_of_interest: ["delimited-sections"]`. Expected output: list of files containing onboarding-agent delimiters, by path. Fallback: the current inline enumeration logic.

- [ ] **Step 2: Verify**

Run:
```bash
grep -c "repo-scanner" skills/upgrade/SKILL.md
```
Expected: ≥ 1.

Run:
```bash
grep -c "### Fallback\|Fallback (if" skills/upgrade/SKILL.md
```
Expected: ≥ 1.

- [ ] **Step 3: Commit**

```bash
git add skills/upgrade/SKILL.md
git commit -m "refactor(upgrade): delegate candidate-file enumeration to repo-scanner subagent"
```

---

## Task 6 — Verification

This task has no commit. It is the final gate before the PR is opened.

- [ ] **Step 1: Static grep — onboarding dispatches and has fallbacks**

```bash
grep -c "repo-scanner\|artifact-verifier\|audit-collector" skills/onboarding/SKILL.md
```
Expected: ≥ 5.

```bash
grep -c "### Fallback\|Fallback (if" skills/onboarding/SKILL.md
```
Expected: ≥ 3.

- [ ] **Step 2: Static grep — inline scan lives only in the fallback**

Run:
```bash
awk '/^## Step 2:/,/^## Step 3:/' skills/onboarding/SKILL.md | head -20
```
Expected: the first 10 lines after the heading describe the dispatch, not the bullet-list scan.

- [ ] **Step 3: Wave 2 assertions (if Wave 2 is included)**

Repeat the Task 4 Step 3 and Task 5 Step 2 greps. Expected: all pass.

- [ ] **Step 4: Manual E2E walkthrough — onboarding on a scratch repo**

In a scratch directory (not the plugin repo), create a minimal Python project:

```bash
mkdir -p /tmp/onboarding-subagent-test
cd /tmp/onboarding-subagent-test
echo "[project]\nname = 'demo'" > pyproject.toml
mkdir src && echo "print('hello')" > src/main.py
git init -q && git add . && git commit -q -m "initial"
```

Then, in a Claude Code session pointed at this scratch directory with the plugin installed, invoke `/onboarding`. Expected outcomes:

1. Step 1 detects language.
2. Step 2 prints a short message like "Scanning repository via repo-scanner subagent…" and then proceeds to Step 3 with coding inferred.
3. Steps 3–5 work as before; the chosen setup skill runs and writes files.
4. Step 5a prints `✓ Artifacts verified` (or lists issues if any).
5. Step 7 asks about running an audit. On `y`, a summary appears; on `n`, the step is silent.

Document the result in the PR description (terminal paste).

- [ ] **Step 5: Manual E2E walkthrough — subagent unavailable fallback**

Simulate a subagent failure (e.g. temporarily rename the `repo-scanner` definition file so the dispatch errors). Invoke `/onboarding` in the scratch repo. Expected:

1. The `⚠ repo-scanner subagent unavailable — falling back to inline detection.` line appears.
2. The inline fallback still produces a use-case inference.
3. The rest of the flow completes.

Restore the subagent definition after the test.

- [ ] **Step 6: Cross-check spec Success Criteria**

Open `docs/superpowers/specs/2026-04-21-onboarding-subagent-orchestration-design.md` and tick every bullet in the Success Criteria section. Any unmet criterion blocks the PR.

- [ ] **Step 7: Open PR**

```bash
gh pr create --title "Refactor onboarding orchestrator to dispatch plugin-internal subagents" --body "$(cat <<'EOF'
## Summary

- Delegate Step 2 repo scan in `onboarding` to the `repo-scanner` subagent
- Add Step 5a artifact verification via `artifact-verifier`
- Add Step 7 optional post-setup audit via `audit-collector`
- (Optional Wave 2) mirror the pattern in `checkup` and `upgrade`

## Dependency

Depends on Initiative #1 (plugin-internal subagents). This PR assumes the `repo-scanner`, `artifact-verifier`, and `audit-collector` subagent definitions exist in the plugin catalog.

## Spec

`docs/superpowers/specs/2026-04-21-onboarding-subagent-orchestration-design.md`

## Test plan

- [x] Static grep: onboarding dispatches + fallbacks present
- [x] Static grep: inline scan lives only in the fallback subsection
- [x] Manual E2E: onboarding on a fresh Python scratch repo
- [x] Manual E2E: subagent-unavailable fallback path

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review (performed at plan authoring time)

- **Spec coverage:** Every Success Criterion in the spec maps to a task. Agent dispatch present → Task 2 & 3 greps. Fallback present → Task 3 Step 4. Inline scan moved → Task 6 Step 2. Verification step exists → Task 3 Step 2. Wave 2 independently testable → Tasks 4 and 5 each have their own verify step. Initiative #1 gate → Task 1.
- **Placeholders:** No "TBD", "similar to Task N", or unspecified steps. Each Edit operation names its target section and the exact shape of the replacement.
- **Type consistency:** Subagent names (`repo-scanner`, `artifact-verifier`, `audit-collector`) are spelled identically in every task and match the spec.
- **Dependency explicit:** Task 1 is a hard gate. If it fails, the plan halts. The gate checks both the catalog's existence and the three specific names this plan consumes.
- **Known soft edge:** The manual E2E in Task 6 Step 5 requires simulating a subagent failure; the plan assumes the tester can rename a file temporarily. If Initiative #1 puts definitions in a read-only location, the tester must adapt (e.g. invoke in a worktree where the rename is allowed).
