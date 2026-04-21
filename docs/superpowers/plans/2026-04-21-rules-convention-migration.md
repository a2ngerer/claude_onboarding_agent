# Rules Convention Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate plugin-generated rule files from `claude_instructions/` to the Claude-native `.claude/rules/` namespace, add a shared opt-in migration procedure, and lock the extraction whitelist into the plugin's authoring docs.

**Architecture:** Markdown-based refactor of existing SKILL.md files. A new shared helper (`skills/_shared/migrate-claude-instructions.md`) describes the migration procedure; `checkup` and `upgrade` consume it. Generator skills switch their output path. No executable code — SKILL.md files are prompts Claude follows at runtime.

**Tech Stack:** Markdown, Claude Code skill framework. Verification is grep-based (static) plus a documented manual E2E walkthrough.

**Spec:** `docs/superpowers/specs/2026-04-21-rules-convention-migration-design.md` — read it first. Every task below references decisions made there.

---

## Conventions for this plan

- Commit messages follow the existing repo style (`feat(scope):`, `refactor(scope):`, `docs(scope):`, `chore(scope):`). Seven commits total, one per task group (G1–G4 are bundled).
- "Test" for markdown refactor = `grep` before and after. "Failing test" = grep shows the old content. "Passing test" = grep confirms the new content and the absence of the old.
- **Never** use `git commit --no-verify`. If a pre-commit hook fails, fix the underlying issue.
- Language for all committed artifacts: English (repo rule).

## File Structure

**New:**
- `skills/_shared/migrate-claude-instructions.md` — shared migration procedure

**Modified:**
- `CLAUDE.md` (repo root) — add extraction whitelist + threshold under the "Skill Authoring Rules" section
- `skills/onboarding/SKILL.md` — remove `claude_instructions/` references
- `skills/checkup/SKILL.md` — integrate migration offer via shared helper
- `skills/upgrade/SKILL.md` — integrate migration offer via shared helper
- `skills/academic-writing-setup/SKILL.md` — path rewrites
- `skills/data-science-setup/SKILL.md` — path rewrites
- `skills/web-development-setup/SKILL.md` — path rewrites
- `skills/knowledge-base-builder/SKILL.md` — path rewrites
- `README.md` (if it references the old path)
- `skills/_shared/*` (audit any existing shared docs)

---

## Task 1 — Foundation: Authoring Docs in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (repo root)

- [ ] **Step 1: Verify current CLAUDE.md has the "Skill Authoring Rules" section**

Run: `grep -n "Skill Authoring Rules" CLAUDE.md`
Expected: Returns a line number (the section exists).

- [ ] **Step 2: Edit CLAUDE.md — append a "Rule File Extraction" subsection under "Skill Authoring Rules"**

Insert the following block immediately before the closing of the "Skill Authoring Rules" section (use the Edit tool; the exact anchor is the last bullet in that section):

```markdown

## Rule File Extraction

When a setup skill produces rule-like content for the user's project, apply this rule:

**Inline in CLAUDE.md if both hold:**
1. The topic is not on the extraction whitelist below, AND
2. The rule block is shorter than 25 lines total.

**Otherwise, extract to `.claude/rules/<filename>.md`.**

### Extraction Whitelist (always extracted, regardless of length)

| Filename | Owning Skill | Purpose |
|---|---|---|
| `writing-style.md` | academic-writing-setup | Voice, tense, section rules |
| `citation-rules.md` | academic-writing-setup | `.bib` conventions, no-invented-citations |
| `obsidian-cli.md` | knowledge-base-builder | CLI command reference (read-on-demand) |
| `data-schema.md` | data-science-setup | Datasets, columns, lineage |
| `evaluation-protocol.md` | data-science-setup | Metrics, splits, baselines |
| `api-conventions.md` | web-development-setup | Route layout, error shape, auth |
| `component-structure.md` | web-development-setup | Atomic/container split, colocation |
| `env-vars.md` | web-development-setup | Public-prefix rules, secret stores |

**Topic exclusivity:** Each whitelist filename has exactly one owning skill. No two skills ever write the same filename. Adding a new topic or owner requires a spec update, not an ad-hoc skill change.

**Collision policy:** Skills must skip the write if the target file already exists, logging `Skipped .claude/rules/<name>.md (already exists)`. Explicit regeneration is only via `checkup --rebuild` or `upgrade`.
```

- [ ] **Step 3: Verify the section was added**

Run: `grep -c "Extraction Whitelist" CLAUDE.md`
Expected: `1`

Run: `grep -c "writing-style.md" CLAUDE.md`
Expected: `1` (the row in the table)

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): add rule file extraction whitelist and threshold"
```

---

## Task 2 — Shared Migration Helper

**Files:**
- Create: `skills/_shared/migrate-claude-instructions.md`

- [ ] **Step 1: Verify the target path is currently empty**

Run: `test -f skills/_shared/migrate-claude-instructions.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create `skills/_shared/migrate-claude-instructions.md` with the following content**

```markdown
# Migrate claude_instructions/ → .claude/rules/

Shared procedure consumed by the `checkup` and `upgrade` skills. When a user project contains a legacy `claude_instructions/` folder, this procedure offers and executes the migration to the `.claude/rules/` convention. Read before offering migration.

## Detection

Check in this order:

1. If `.claude/.migration-declined` exists in the user's project, **silently skip this entire procedure**. The user has already declined.
2. If `claude_instructions/` does not exist as a directory at the project root, skip silently.
3. Otherwise, proceed to Preview.

## Whitelist (plugin-owned filenames)

Only these eight filenames are migrated. Any other file in `claude_instructions/` is considered user-custom and stays in place.

| Filename | Owning Skill |
|---|---|
| `writing-style.md` | academic-writing-setup |
| `citation-rules.md` | academic-writing-setup |
| `obsidian-cli.md` | knowledge-base-builder |
| `data-schema.md` | data-science-setup |
| `evaluation-protocol.md` | data-science-setup |
| `api-conventions.md` | web-development-setup |
| `component-structure.md` | web-development-setup |
| `env-vars.md` | web-development-setup |

## Preview (dry-run)

Before asking the user to confirm, present a block like this (replace the example rows with actual findings):

```
Detected legacy layout: claude_instructions/

Files to migrate to .claude/rules/:
- claude_instructions/writing-style.md → .claude/rules/writing-style.md
- claude_instructions/citation-rules.md → .claude/rules/citation-rules.md

Files to leave in place (not on plugin whitelist):
- claude_instructions/my-custom-notes.md

Target-file conflicts (source stays, manual reconciliation needed):
- .claude/rules/writing-style.md already exists

CLAUDE.md pointer rewrites:
- Line 42: "See claude_instructions/writing-style.md for voice" → ".claude/rules/writing-style.md"

Manual review needed (not auto-rewritten):
- Line 58: markdown link [rules](claude_instructions/writing-style.md)

After migration:
- claude_instructions/ will be removed only if empty.
- External references (wikis, blog posts) to claude_instructions/ will not be rewritten.
```

Then prompt exactly: `Proceed with migration? (yes/no)`

## Execution on "yes"

For **each file** on the whitelist present in `claude_instructions/`:

1. If `.claude/rules/<name>.md` already exists: skip this file and log `Skipped <name>.md (target exists, manual reconciliation needed)`.
2. Ensure the target directory exists: `mkdir -p .claude/rules`.
3. Check if the source is tracked by git:

   ```
   git ls-files --error-unmatch claude_instructions/<name>.md
   ```

   - Exit code `0` (tracked): `git mv claude_instructions/<name>.md .claude/rules/<name>.md`
   - Non-zero (untracked): plain `mv claude_instructions/<name>.md .claude/rules/<name>.md`

   Per-file decision; do not treat the folder as a unit. Mixed tracked/untracked is expected.

For CLAUDE.md pointer rewrites:

1. For each whitelist filename `<name>`, replace every exact-plaintext occurrence of `claude_instructions/<name>.md` with `.claude/rules/<name>.md`.
2. Match as a whole token — do not do substring regex. Example transformation:
   - Before: `See claude_instructions/writing-style.md for voice.`
   - After:  `See .claude/rules/writing-style.md for voice.`
3. Do **not** rewrite markdown link syntax (e.g., `[label](claude_instructions/foo.md)`), `./claude_instructions/` variants, or any other form. These are listed in the preview under "Manual review needed" and stay untouched.

After all files are processed:

1. If `claude_instructions/` is now empty, remove it (`rmdir claude_instructions`).
2. If it still contains files (user-custom leftovers), leave it in place and state that explicitly in the summary.

## Execution on "no"

1. Write marker file: `.claude/.migration-declined` (empty file; content ignored).
2. Tell the user: "Migration declined. Marker written to `.claude/.migration-declined`. Delete it to be asked again."

## Post-migration summary

Report to the user:

- Files migrated (count and list)
- Files left in place (user-custom, count and list)
- CLAUDE.md pointer rewrites applied (count)
- Manual-review items (count and list)
- Final state of `claude_instructions/` (removed / still present with N files)

## Re-prompt behavior

The skill consuming this helper MUST re-offer migration on every invocation as long as `claude_instructions/` exists AND `.claude/.migration-declined` does not exist. A single-session suppression is not enough.
```

- [ ] **Step 3: Verify file exists and contains the whitelist**

Run: `test -f skills/_shared/migrate-claude-instructions.md && echo OK`
Expected: `OK`

Run: `grep -c "writing-style.md" skills/_shared/migrate-claude-instructions.md`
Expected: `3` or more (once in whitelist table, once in preview example, once in pointer-rewrite example)

- [ ] **Step 4: Commit**

```bash
git add skills/_shared/migrate-claude-instructions.md
git commit -m "feat(shared): add claude_instructions to .claude/rules migration helper"
```

---

## Task 3 — Generators: Path Rewrites (G1–G4 in one commit)

**Files:**
- Modify: `skills/academic-writing-setup/SKILL.md`
- Modify: `skills/data-science-setup/SKILL.md`
- Modify: `skills/web-development-setup/SKILL.md`
- Modify: `skills/knowledge-base-builder/SKILL.md`

- [ ] **Step 1: Verify current state — old path is present in all four skills**

Run:
```bash
grep -c "claude_instructions/" skills/academic-writing-setup/SKILL.md
grep -c "claude_instructions/" skills/data-science-setup/SKILL.md
grep -c "claude_instructions/" skills/web-development-setup/SKILL.md
grep -c "claude_instructions/" skills/knowledge-base-builder/SKILL.md
```
Expected: each count is ≥1 (exact numbers come from the grep output from the spec-phase analysis: academic-writing ~7, data-science ~6, web-dev ~8, knowledge-base ~5).

- [ ] **Step 2: Replace all occurrences in academic-writing-setup**

Use the Edit tool with `replace_all: true`:
- File: `skills/academic-writing-setup/SKILL.md`
- Find: `claude_instructions/`
- Replace with: `.claude/rules/`

- [ ] **Step 3: Replace all occurrences in data-science-setup**

Use the Edit tool with `replace_all: true`:
- File: `skills/data-science-setup/SKILL.md`
- Find: `claude_instructions/`
- Replace with: `.claude/rules/`

- [ ] **Step 4: Replace all occurrences in web-development-setup**

Use the Edit tool with `replace_all: true`:
- File: `skills/web-development-setup/SKILL.md`
- Find: `claude_instructions/`
- Replace with: `.claude/rules/`

- [ ] **Step 5: Replace all occurrences in knowledge-base-builder**

Use the Edit tool with `replace_all: true`:
- File: `skills/knowledge-base-builder/SKILL.md`
- Find: `claude_instructions/`
- Replace with: `.claude/rules/`

- [ ] **Step 6: Verify all four skills now reference only `.claude/rules/`**

Run:
```bash
grep -l "claude_instructions/" skills/academic-writing-setup/SKILL.md skills/data-science-setup/SKILL.md skills/web-development-setup/SKILL.md skills/knowledge-base-builder/SKILL.md
```
Expected: no output (no files match).

Run:
```bash
grep -c "\.claude/rules/" skills/academic-writing-setup/SKILL.md
grep -c "\.claude/rules/" skills/data-science-setup/SKILL.md
grep -c "\.claude/rules/" skills/web-development-setup/SKILL.md
grep -c "\.claude/rules/" skills/knowledge-base-builder/SKILL.md
```
Expected: each count ≥1 (matches the pre-change count of `claude_instructions/`).

- [ ] **Step 7: Spot-check one generator for sanity**

Run: `grep -n "\.claude/rules/writing-style.md" skills/academic-writing-setup/SKILL.md`
Expected: at least one hit.

- [ ] **Step 8: Commit**

```bash
git add skills/academic-writing-setup/SKILL.md skills/data-science-setup/SKILL.md skills/web-development-setup/SKILL.md skills/knowledge-base-builder/SKILL.md
git commit -m "refactor(skills): migrate generator rule paths to .claude/rules/"
```

---

## Task 4 — Bootstrap: onboarding SKILL.md

**Files:**
- Modify: `skills/onboarding/SKILL.md`

- [ ] **Step 1: Verify onboarding still references the old path**

Run: `grep -c "claude_instructions/" skills/onboarding/SKILL.md`
Expected: ≥1.

- [ ] **Step 2: Replace all occurrences**

Use the Edit tool with `replace_all: true`:
- File: `skills/onboarding/SKILL.md`
- Find: `claude_instructions/`
- Replace with: `.claude/rules/`

- [ ] **Step 3: Verify**

Run: `grep -c "claude_instructions/" skills/onboarding/SKILL.md`
Expected: `0`.

Run: `grep -c "\.claude/rules/" skills/onboarding/SKILL.md`
Expected: ≥1 (same count as before-change).

- [ ] **Step 4: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "refactor(onboarding): point routing references to .claude/rules/"
```

---

## Task 5 — Checkup: Integrate Migration Offer

**Files:**
- Modify: `skills/checkup/SKILL.md`

- [ ] **Step 1: Read the current checkup SKILL.md to locate the detection flow**

Run: `grep -n "existing" skills/checkup/SKILL.md | head -20`
Use the Read tool on `skills/checkup/SKILL.md` to understand the current detection/routing structure. Identify the step where the skill scans the user project for existing setup artifacts — that is where the migration detection must hook in.

- [ ] **Step 2: Add a migration-detection step in the checkup flow**

Insert a new procedural step into `skills/checkup/SKILL.md`, placed in the detection phase (after the skill has identified that a prior setup exists, before it decides between `rebuild` and `improve`):

```markdown
### Legacy Layout Check

Before deciding on rebuild vs. improve, check for legacy rule-file layouts:

1. Read `skills/_shared/migrate-claude-instructions.md` and follow its **Detection** section.
2. If detection triggers (the folder exists and `.migration-declined` does not), run the full migration procedure from the helper (Preview → user decision → Execution).
3. After the migration step completes (either way), resume the normal checkup flow.

Do not suppress the migration prompt within a session — re-offer on every `checkup` invocation until the user either migrates or writes `.migration-declined`.
```

Exact placement: add as a new subsection right after the "Detection" (or equivalent) section. If no equivalent exists, add it as the **first** procedural step after the skill's front matter and intro.

- [ ] **Step 3: Verify the helper is referenced**

Run: `grep -c "_shared/migrate-claude-instructions.md" skills/checkup/SKILL.md`
Expected: `1`.

Run: `grep -c "Legacy Layout Check" skills/checkup/SKILL.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add skills/checkup/SKILL.md
git commit -m "feat(checkup): detect and offer migration from claude_instructions/"
```

---

## Task 6 — Upgrade: Integrate Migration Offer

**Files:**
- Modify: `skills/upgrade/SKILL.md`

- [ ] **Step 1: Read the current upgrade SKILL.md to locate the detection/scan flow**

Use the Read tool on `skills/upgrade/SKILL.md`. Identify where the skill scans the project for existing plugin artifacts (CLAUDE.md sections, generated files).

- [ ] **Step 2: Add a migration-detection step in the upgrade flow**

Insert a new procedural subsection into `skills/upgrade/SKILL.md`, placed immediately after the scan phase and before any file-level diff/preview:

```markdown
### Legacy Layout Check

Before diffing or previewing upgrade changes, check for legacy rule-file layouts:

1. Read `skills/_shared/migrate-claude-instructions.md` and follow its **Detection** section.
2. If detection triggers, run the full migration procedure from the helper (Preview → user decision → Execution). The migration preview and the upgrade preview are separate — show the migration preview first and let the user decide, then proceed.
3. After the migration step completes, resume the normal upgrade flow. The rest of the upgrade diff will already reflect the post-migration layout.
```

- [ ] **Step 3: Verify**

Run: `grep -c "_shared/migrate-claude-instructions.md" skills/upgrade/SKILL.md`
Expected: `1`.

Run: `grep -c "Legacy Layout Check" skills/upgrade/SKILL.md`
Expected: `1`.

- [ ] **Step 4: Commit**

```bash
git add skills/upgrade/SKILL.md
git commit -m "feat(upgrade): detect and offer migration from claude_instructions/"
```

---

## Task 7 — Audit: README and shared docs

**Files:**
- Potentially: `README.md`
- Potentially: `skills/_shared/*.md` (existing files, not the new helper)

- [ ] **Step 1: Grep for remaining references**

Run: `grep -rn "claude_instructions/" --include="*.md" . | grep -v "docs/superpowers/" | grep -v "skills/checkup/" | grep -v "skills/upgrade/" | grep -v "skills/_shared/migrate-claude-instructions.md"`

(Excludes `docs/superpowers/` because historical specs are intentionally not touched. Excludes `checkup`, `upgrade`, and the new helper because those are expected to mention the legacy path in the migration context.)

Expected: zero lines. If any lines appear, investigate each and proceed to Step 2.

- [ ] **Step 2: For each surviving reference, decide and fix**

For each line the grep returned:

- If it is a **path reference** used by the plugin (e.g., a generator writing output), replace `claude_instructions/` → `.claude/rules/` using the Edit tool.
- If it is **prose describing the old convention** (e.g., a historical explanation), judge whether it is still relevant. Options: rewrite to describe the new convention, or delete the line.
- If it is a **migration-context reference** (e.g., README describing migration behavior), leave it but verify the context is clear.

Apply each fix. After fixing, re-run the Step 1 grep.

- [ ] **Step 3: Verify zero unexpected references remain**

Re-run the Step 1 grep. Expected: zero lines (or only the expected exclusions).

- [ ] **Step 4: Commit**

If any files were modified:

```bash
git add <modified files>
git commit -m "chore: audit and fix residual claude_instructions references"
```

If no files were modified: skip the commit. State in the PR description that the audit found no additional references.

---

## Task 8 — Verification

This task has no commit. It is the final gate before the PR is opened.

- [ ] **Step 1: Static grep — generators and bootstrap must be clean**

Run:
```bash
grep -l "claude_instructions/" skills/onboarding/SKILL.md skills/academic-writing-setup/SKILL.md skills/data-science-setup/SKILL.md skills/web-development-setup/SKILL.md skills/knowledge-base-builder/SKILL.md
```
Expected: no output. These five skills must not reference `claude_instructions/` in any form.

- [ ] **Step 2: Static grep — migration-aware skills reference the helper**

Run:
```bash
grep "_shared/migrate-claude-instructions" skills/checkup/SKILL.md skills/upgrade/SKILL.md
```
Expected: at least one hit per file.

- [ ] **Step 3: Static grep — CLAUDE.md has authoring whitelist**

Run: `grep -c "Extraction Whitelist" CLAUDE.md`
Expected: `1`.

- [ ] **Step 4: Manual E2E walkthrough — fresh migration**

In a scratch directory (not the plugin repo), create a synthetic legacy setup:

```bash
mkdir -p /tmp/rules-migration-test/claude_instructions /tmp/rules-migration-test/.claude
cd /tmp/rules-migration-test
echo "# Writing Style" > claude_instructions/writing-style.md
echo "# Citation Rules" > claude_instructions/citation-rules.md
echo "# My Personal Notes" > claude_instructions/my-custom-notes.md
cat > CLAUDE.md <<EOF
# Test Project

See claude_instructions/writing-style.md for voice.
See claude_instructions/citation-rules.md for bib rules.
Legacy link: [rules](claude_instructions/writing-style.md)
EOF
git init -q && git add . && git commit -q -m "initial"
```

Then, in a Claude Code session pointed at this scratch directory, invoke `/checkup`. Expected outcomes:

1. The migration preview lists `writing-style.md` and `citation-rules.md` as to-be-migrated, `my-custom-notes.md` as staying, and the markdown link on the `Legacy link:` line as "manual review needed".
2. On `yes`:
   - `.claude/rules/writing-style.md` and `.claude/rules/citation-rules.md` exist.
   - `CLAUDE.md` lines 3 and 4 are rewritten; line 5 (markdown link) is unchanged.
   - `claude_instructions/my-custom-notes.md` still exists; the folder is not removed.
3. On `no`:
   - `.claude/.migration-declined` exists.
   - Re-running `/checkup` does not re-prompt.
   - Deleting the marker causes the prompt to return.

Document the result in the PR description (screenshots or terminal paste).

- [ ] **Step 5: Cross-check spec Success Criteria**

Open `docs/superpowers/specs/2026-04-21-rules-convention-migration-design.md` and tick every bullet in the "Success Criteria" section against the current state of the branch. Any unmet criterion blocks the PR.

- [ ] **Step 6: Open PR**

```bash
gh pr create --title "Rules convention migration: claude_instructions/ → .claude/rules/" --body "$(cat <<'EOF'
## Summary

- Migrate plugin-generated rule files from `claude_instructions/` to `.claude/rules/`
- Add shared migration helper for `checkup` and `upgrade`
- Lock extraction whitelist + 25-line threshold into `CLAUDE.md` authoring rules

## Spec

`docs/superpowers/specs/2026-04-21-rules-convention-migration-design.md`

## Test plan

- [x] Static grep: generator + bootstrap skills are clean
- [x] Static grep: migration-aware skills reference the helper
- [x] Manual E2E: fresh migration with whitelist + user-custom files
- [x] Manual E2E: decline path writes marker and suppresses re-prompt

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review (performed at plan authoring time)

- **Spec coverage:** Every Success Criterion in the spec maps to a task. Code-level grep → Task 8 Step 1. Migration detection → Task 8 Step 4.1. Migration decline → Task 8 Step 4.3. Whitelist-only migration → Task 8 Step 4.2 (the `my-custom-notes.md` case). Collision behavior → handled by Task 5/6 referencing the helper (Task 2) which specifies skip-on-exists; implementer should verify by re-running `/coding-setup` or similar on an already-migrated project. Authoring doc → Task 1.
- **Placeholders:** No "TBD", "similar to Task N", or unspecified steps. Each Edit operation has explicit find/replace strings.
- **Type consistency:** Helper filename `migrate-claude-instructions.md` is referenced identically in Tasks 2, 5, 6, 8. Whitelist filenames match across spec, helper content, CLAUDE.md block, and verification greps.
- **Known soft edge:** Task 7 Step 2 requires human judgment on residual references. That is correct — an audit by definition cannot be fully automated.
