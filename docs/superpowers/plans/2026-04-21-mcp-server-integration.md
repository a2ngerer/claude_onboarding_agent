# MCP Server Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a conservative, opt-in MCP recommendation layer to `coding-setup`, `web-development-setup`, `design-setup`, and `office-setup`. MCPs are registered at runtime via `claude mcp add` triggered by the skill; the plugin manifest is NOT extended with an `mcpServers` field. A shared helper (`skills/_shared/offer-mcp.md`) owns the offer/prompt/execute/record pattern so the four skills stay DRY.

**Architecture:** Markdown-only refactor. One new shared helper plus four SKILL.md edits and one checkup addition. Verification is grep-based (static) plus a manual E2E walkthrough per affected skill.

**Tech Stack:** Markdown, Claude Code skill framework, `claude mcp add` CLI (user-side, run by the skill via Bash at runtime).

**Spec:** `docs/superpowers/specs/2026-04-21-mcp-server-integration-design.md` — read it first. Every task below references decisions made there.

---

## Conventions for this plan

- Commit messages follow the existing repo style (`feat(scope):`, `refactor(scope):`, `docs(scope):`, `chore(scope):`). Six commits total, one per task group.
- "Test" for markdown refactor = `grep` before and after. "Failing test" = grep shows the old content. "Passing test" = grep confirms the new content and the absence of the old.
- **Never** use `git commit --no-verify`. If a pre-commit hook fails, fix the underlying issue.
- Language for all committed artifacts: English (repo rule).

## File Structure

**New:**
- `skills/_shared/offer-mcp.md` — shared MCP-offer procedure

**Modified:**
- `skills/coding-setup/SKILL.md` — add GitHub MCP offer step
- `skills/web-development-setup/SKILL.md` — add GitHub MCP offer step
- `skills/design-setup/SKILL.md` — add Figma MCP offer step
- `skills/office-setup/SKILL.md` — add Gmail/Calendar/Drive MCP offer steps
- `skills/checkup/SKILL.md` — add Check 4.3 "Use case suggests MCP that is not registered"

**Not modified (deliberate):**
- `.claude-plugin/plugin.json` — no `mcpServers` field per spec decision
- `skills/knowledge-base-builder/SKILL.md` — keeps existing Obsidian CLI + subagent pattern
- All other skills — no current MCP use case

---

## Task 1 — Shared Offer-MCP Helper

**Files:**
- Create: `skills/_shared/offer-mcp.md`

- [ ] **Step 1: Verify the target path does not already exist**

Run: `test -f skills/_shared/offer-mcp.md && echo EXISTS || echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: Create `skills/_shared/offer-mcp.md` with the following content**

```markdown
# Offer MCP Server (shared procedure)

Shared procedure consumed by `coding-setup`, `web-development-setup`, `design-setup`, and `office-setup` when a setup skill wants to offer an MCP server registration to the user. Read this file before the first offer in a skill flow.

## Contract

The calling skill passes the following parameters (inline in its own prose, not as structured arguments):

| Parameter | Example | Purpose |
|---|---|---|
| `mcp_slug` | `github` | Identifier used in `claude mcp add <slug> ...` and in skill state as `<slug>_installed` |
| `trigger_condition` | "user's project has a GitHub remote" | Condition under which the offer is made. If false, the offer is silently skipped — NO prompt shown. |
| `capability_line` | "Access GitHub issues and PRs from Claude." | One-sentence description, adapted to detected language |
| `install_command` | `claude mcp add github npx -- -y @modelcontextprotocol/server-github` | Exact Bash command, copy-pasteable |
| `auth_type` | `api_token` or `oauth` | Drives the auth-flow note in the prompt |
| `auth_detail` | env var name (`GITHUB_PERSONAL_ACCESS_TOKEN`) or OAuth note | Inserted into the prompt |
| `pointer_link` | `https://github.com/modelcontextprotocol/servers` | Written into the CLAUDE.md pointer on yes or later |

Slugs, install commands, and pointer links MUST be sourced from `docs/anchors/mcp-servers.md`. Skills never hardcode a slug or command that conflicts with the anchor.

## Step 1: Check trigger condition

If `trigger_condition` is false, skip this procedure entirely — no prompt, no state change.

## Step 2: Check if already registered

Run via Bash: `claude mcp list 2>/dev/null | grep -q "^<mcp_slug>\b" && echo REGISTERED || echo NOT_REGISTERED`

- If `REGISTERED`: log `Skipped <mcp_slug> MCP offer (already registered)` to the skill's state and proceed to Step 5 with `<mcp_slug>_installed: true`. No prompt.
- Else: proceed to Step 3.

## Step 3: Prompt the user

Adapt the following to the detected language. Keep the install command and slug verbatim:

```
Offer: <mcp_slug> MCP server

<capability_line>

Install command: <install_command>

Auth: [for api_token]
  Set <auth_detail> in your shell profile before first use.
  See <pointer_link> for how to generate the token.

Auth: [for oauth]
  On first use of a <mcp_slug> tool, Claude Code opens a browser window for the provider's OAuth consent screen.
  The token is stored in Claude Code's credential store; this plugin never touches it.
  Granting access lets Claude read your data per the scopes shown on the consent screen — review before approving.

(yes / no / later)
```

- **yes** → Step 4 (execute).
- **no** → Record `<mcp_slug>_installed: false`. No CLAUDE.md pointer. Skip to Step 5.
- **later** → Record `<mcp_slug>_installed: false`, `<mcp_slug>_deferred: true`. Write a short deferred pointer into CLAUDE.md (see Step 5). Skip to Step 5.

## Step 4: Execute registration

Run via Bash exactly: `<install_command>`

- Exit code `0`: record `<mcp_slug>_installed: true`. Proceed to Step 5.
- Non-zero: surface the stderr verbatim to the user, warn once:
  > "⚠ Could not register <mcp_slug>. Error above. Continuing without it — you can retry manually with: <install_command>"
  Record `<mcp_slug>_installed: false`. Proceed to Step 5.

Never block the rest of the skill flow on a non-zero exit.

## Step 5: Write CLAUDE.md pointer

When the skill writes or updates its delimited CLAUDE.md section, include a `## Configured MCP servers` subsection with one bullet per offered MCP, using this exact pattern:

```
## Configured MCP servers
- <mcp_slug>: <capability_line> Auth: <auth summary>. See <pointer_link>.
```

Auth summary:
- `api_token` → `requires <auth_detail>`
- `oauth` → `OAuth via Claude Code`

If `<mcp_slug>_installed: false` AND `<mcp_slug>_deferred: true`, emit instead:
```
- <mcp_slug>: deferred — run `<install_command>` when ready. See <pointer_link>.
```

If `<mcp_slug>_installed: false` AND NOT deferred (plain "no"), do NOT emit a line for this MCP.

If no MCP in the skill's flow ended up on the list (all skipped or all plain-no), do NOT write the `## Configured MCP servers` heading at all — avoid empty sections.

## Step 6: Completion summary

Include one line per MCP the skill considered, in the skill's completion summary:

- `✓ <mcp_slug> MCP registered` (on yes + success)
- `⚠ <mcp_slug> MCP registration failed — manual retry: <install_command>` (on yes + failure)
- `— <mcp_slug> MCP deferred — run <install_command> when ready` (on later)
- `— <mcp_slug> MCP declined` (on no)
- Omit the line entirely if the trigger condition was false.

## Re-run behavior

Re-invoking the same setup skill re-runs the offer. That is intentional — re-running is the documented path to reconsider the choice. Skills MUST NOT persist a "user declined" marker that suppresses the offer permanently.
```

- [ ] **Step 3: Verify the file exists and contains the required anchors**

Run: `test -f skills/_shared/offer-mcp.md && echo OK`
Expected: `OK`

Run: `grep -c "claude mcp add" skills/_shared/offer-mcp.md`
Expected: ≥ 3 (contract table, prompt template, manual retry line).

Run: `grep -c "yes / no / later" skills/_shared/offer-mcp.md`
Expected: 1.

Run: `grep -c "GITHUB_PERSONAL_ACCESS_TOKEN" skills/_shared/offer-mcp.md`
Expected: ≥ 1.

Run: `grep -c "Configured MCP servers" skills/_shared/offer-mcp.md`
Expected: ≥ 2.

- [ ] **Step 4: Commit**

```bash
git add skills/_shared/offer-mcp.md
git commit -m "feat(shared): add offer-mcp helper for opt-in MCP registration"
```

---

## Task 2 — coding-setup: GitHub MCP offer

**Files:**
- Modify: `skills/coding-setup/SKILL.md`

- [ ] **Step 1: Read the current coding-setup SKILL.md to locate insertion points**

Use the Read tool on `skills/coding-setup/SKILL.md`. Identify:
1. The context-questions block (Step 2 or equivalent).
2. The artifact-generation block where the CLAUDE.md template lives (Step 3 or equivalent).
3. The completion-summary block (final Step).

- [ ] **Step 2: Add a GitHub MCP offer step**

Insert a new subsection immediately AFTER the last context question and BEFORE the artifact-generation step. Exact text to add (adapt the step number to the skill's local numbering — if the skill uses "Step 3: Generate Artifacts", insert this as "Step 3: Offer GitHub MCP" and renumber generation to "Step 4"):

```markdown
## Step 3: Offer GitHub MCP (conditional)

Read `skills/_shared/offer-mcp.md` and follow it with these parameters:

- `mcp_slug`: `github`
- `trigger_condition`: project is git-initialized AND has a GitHub remote. Check via Bash:
  `git remote -v 2>/dev/null | grep -q 'github.com' && echo YES || echo NO`
  If `NO`, skip this step entirely — no prompt, no CLAUDE.md change.
- `capability_line`: "Access GitHub issues, PRs, and reviews directly via the GitHub API instead of shelling out to `gh`."
- `install_command`: `claude mcp add github npx -- -y @modelcontextprotocol/server-github`
- `auth_type`: `api_token`
- `auth_detail`: `GITHUB_PERSONAL_ACCESS_TOKEN` (generate at https://github.com/settings/tokens — scope `repo` for private repos, else `public_repo`)
- `pointer_link`: `https://github.com/modelcontextprotocol/servers/tree/main/src/github`

Record `github_installed` in skill state for use by the CLAUDE.md generator and completion summary.
```

- [ ] **Step 3: Update the CLAUDE.md template to include the Configured MCP servers section**

In the CLAUDE.md template block, add this conditional block AFTER the main instructions and BEFORE the Superpowers block (or wherever conditional sections already live):

```markdown
[Include ONLY if github_installed is true OR github_deferred is true — emitted per skills/_shared/offer-mcp.md Step 5]
## Configured MCP servers
- github: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
```

- [ ] **Step 4: Update the completion summary**

Add a line to the summary block, using the format from `skills/_shared/offer-mcp.md` Step 6.

- [ ] **Step 5: Verify**

Run: `grep -c "_shared/offer-mcp.md" skills/coding-setup/SKILL.md`
Expected: ≥ 1.

Run: `grep -c "claude mcp add github" skills/coding-setup/SKILL.md`
Expected: 1.

Run: `grep -c "GITHUB_PERSONAL_ACCESS_TOKEN" skills/coding-setup/SKILL.md`
Expected: 1.

- [ ] **Step 6: Commit**

```bash
git add skills/coding-setup/SKILL.md
git commit -m "feat(coding-setup): offer opt-in GitHub MCP registration"
```

---

## Task 3 — web-development-setup: GitHub MCP offer

**Files:**
- Modify: `skills/web-development-setup/SKILL.md`

- [ ] **Step 1: Read the skill and locate insertion points**

Same structure as Task 2.

- [ ] **Step 2: Add the GitHub MCP offer step**

Insert the same offer block as Task 2 Step 2, renumbered to fit this skill's step sequence. The `trigger_condition` (git-initialized + GitHub remote) is the same. The `install_command`, `auth_*`, and `pointer_link` values are identical.

- [ ] **Step 3: Update the CLAUDE.md template**

Same conditional `## Configured MCP servers` block as Task 2 Step 3.

- [ ] **Step 4: Update the completion summary**

Same completion-summary line as Task 2 Step 4.

- [ ] **Step 5: Verify**

Run: `grep -c "_shared/offer-mcp.md" skills/web-development-setup/SKILL.md`
Expected: ≥ 1.

Run: `grep -c "claude mcp add github" skills/web-development-setup/SKILL.md`
Expected: 1.

Run: `grep -c "GITHUB_PERSONAL_ACCESS_TOKEN" skills/web-development-setup/SKILL.md`
Expected: 1.

- [ ] **Step 6: Commit**

```bash
git add skills/web-development-setup/SKILL.md
git commit -m "feat(web-development-setup): offer opt-in GitHub MCP registration"
```

---

## Task 4 — design-setup: Figma MCP offer

**Files:**
- Modify: `skills/design-setup/SKILL.md`

- [ ] **Step 1: Read the skill and locate insertion points**

Use the Read tool on `skills/design-setup/SKILL.md`. Identify:
1. Q1 (design tool) — gates the Figma trigger.
2. Artifact-generation step.
3. Completion summary.

- [ ] **Step 2: Add the Figma MCP offer step**

Insert a new subsection AFTER the optional-community-skills block (Step 3 in the current file) and BEFORE the artifact-generation step:

```markdown
## Step 4: Offer Figma MCP (conditional)

Read `skills/_shared/offer-mcp.md` and follow it with these parameters:

- `mcp_slug`: `figma-context`
- `trigger_condition`: Q1 answer is "A) Figma". If the user picked another tool, skip this step entirely.
- `capability_line`: "Read Figma frames directly into Claude's context for UI-to-code work."
- `install_command`: the install command from `docs/anchors/mcp-servers.md` under "Design" (currently: see https://github.com/GLips/Figma-Context-MCP — use the README's documented `claude mcp add` form at registration time; adapt if the anchor is updated).
- `auth_type`: `api_token`
- `auth_detail`: `FIGMA_API_TOKEN` (generate at https://www.figma.com/developers/api#access-tokens — scope: read-only is sufficient)
- `pointer_link`: `https://github.com/GLips/Figma-Context-MCP`

Record `figma-context_installed` in skill state.
```

(Renumber subsequent steps so the skill flow stays sequential.)

- [ ] **Step 3: Update the CLAUDE.md template**

Add the same conditional `## Configured MCP servers` block pattern as Task 2, with `figma-context` as the relevant slug.

- [ ] **Step 4: Update the completion summary**

Same line as Task 2, with `figma-context` substituted.

- [ ] **Step 5: Verify**

Run: `grep -c "_shared/offer-mcp.md" skills/design-setup/SKILL.md`
Expected: ≥ 1.

Run: `grep -c "figma-context" skills/design-setup/SKILL.md`
Expected: ≥ 1.

Run: `grep -c "FIGMA_API_TOKEN" skills/design-setup/SKILL.md`
Expected: 1.

- [ ] **Step 6: Commit**

```bash
git add skills/design-setup/SKILL.md
git commit -m "feat(design-setup): offer opt-in Figma MCP registration"
```

---

## Task 5 — office-setup: Gmail/Calendar/Drive MCP offers

**Files:**
- Modify: `skills/office-setup/SKILL.md`

- [ ] **Step 1: Read the skill and locate insertion points**

Use the Read tool on `skills/office-setup/SKILL.md`. Q1 answers (document types) gate the Gmail/Drive triggers. Calendar follows Gmail.

- [ ] **Step 2: Add the MCP offer step**

Insert a new subsection AFTER Step 2 (context questions) and BEFORE Step 3 (artifact generation):

```markdown
## Step 3: Offer Google Workspace MCPs (conditional)

Read `skills/_shared/offer-mcp.md` once. Then run it for each MCP below in order, skipping any whose trigger condition is false.

### Gmail

- `mcp_slug`: `gmail`
- `trigger_condition`: Q1 answer is "A) Emails and messages" OR "D) All of the above".
- `capability_line`: "Read, search, and send email from your Gmail inbox."
- `install_command`: the current install command from `docs/anchors/mcp-servers.md` under "Productivity" (prefer the official Google Gmail MCP if listed; else the community `gmail-mcp-server` noted in the anchor).
- `auth_type`: `oauth`
- `auth_detail`: "Google OAuth — reads your Gmail inbox per the scopes shown on the consent screen."
- `pointer_link`: see anchor doc.

### Google Calendar

- `mcp_slug`: `google-calendar`
- `trigger_condition`: same as Gmail (Q1 = A or D). Offer Calendar only if Gmail was offered.
- `capability_line`: "Read and create calendar events."
- `install_command`: from `docs/anchors/mcp-servers.md`.
- `auth_type`: `oauth`
- `auth_detail`: "Google OAuth — reads/writes your Google Calendar per the consent screen scopes."
- `pointer_link`: see anchor doc.

### Google Drive

- `mcp_slug`: `google-drive`
- `trigger_condition`: Q1 answer is "B) Reports and proposals" OR "D) All of the above".
- `capability_line`: "Read and search documents in your Google Drive."
- `install_command`: from `docs/anchors/mcp-servers.md`.
- `auth_type`: `oauth`
- `auth_detail`: "Google OAuth — reads your Google Drive per the consent screen scopes."
- `pointer_link`: see anchor doc.

Record `gmail_installed`, `google-calendar_installed`, `google-drive_installed` in skill state.
```

(Renumber subsequent steps.)

- [ ] **Step 3: Update the CLAUDE.md template**

Add the conditional `## Configured MCP servers` block supporting up to three bullets (one per installed/deferred MCP). Use the format from `skills/_shared/offer-mcp.md` Step 5.

- [ ] **Step 4: Update the completion summary**

Add up to three lines using the format from `skills/_shared/offer-mcp.md` Step 6.

- [ ] **Step 5: Verify**

Run: `grep -c "_shared/offer-mcp.md" skills/office-setup/SKILL.md`
Expected: ≥ 1.

Run: `grep -c "gmail" skills/office-setup/SKILL.md`
Expected: ≥ 2 (offer block + CLAUDE.md template).

Run: `grep -c "google-calendar" skills/office-setup/SKILL.md`
Expected: ≥ 2.

Run: `grep -c "google-drive" skills/office-setup/SKILL.md`
Expected: ≥ 2.

Run: `grep -c "OAuth" skills/office-setup/SKILL.md`
Expected: ≥ 1.

- [ ] **Step 6: Commit**

```bash
git add skills/office-setup/SKILL.md
git commit -m "feat(office-setup): offer opt-in Gmail/Calendar/Drive MCP registration"
```

---

## Task 6 — checkup: Check 4.3 "Use case suggests MCP"

**Files:**
- Modify: `skills/checkup/SKILL.md`

- [ ] **Step 1: Read the checkup skill to locate Pass 4**

Use the Read tool on `skills/checkup/SKILL.md`. Locate "Pass 4 — MCP & Skills" and the existing Check 4.2.

- [ ] **Step 2: Add Check 4.3 immediately after Check 4.2**

Insert:

```markdown
**Check 4.3 — Use case suggests MCP that is not registered** `[LOW]`
Condition: `.claude/onboarding-meta.json` records `setup_slug` in {`coding`, `web-development`, `design`, `office`} AND the corresponding recommended MCP (per spec 2026-04-21-mcp-server-integration-design.md) is NOT in `claude mcp list`.
Mapping:
- `coding` → `github` (only if project has a GitHub remote)
- `web-development` → `github` (only if project has a GitHub remote)
- `design` → `figma-context` (only if the recorded design tool is Figma; skip otherwise)
- `office` → `gmail`, `google-calendar`, `google-drive` — flag only the ones whose trigger conditions match the recorded office Q1 answer
Finding title: "Declared use case suggests MCP server(s) that are not registered"
Why: The setup skill offered these MCPs at onboarding time; the user may have declined or deferred. Informational reminder, not an error.
How to apply: Re-run the relevant setup skill to re-offer, or run the `claude mcp add` command directly (see the anchor doc at `docs/anchors/mcp-servers.md`).
```

- [ ] **Step 3: Verify**

Run: `grep -c "Check 4.3" skills/checkup/SKILL.md`
Expected: 1.

Run: `grep -c "mcp-server-integration-design" skills/checkup/SKILL.md`
Expected: 1.

- [ ] **Step 4: Commit**

```bash
git add skills/checkup/SKILL.md
git commit -m "feat(checkup): add Check 4.3 for unregistered recommended MCPs"
```

---

## Task 7 — Verification

This task has no commit. It is the final gate before the PR is opened.

- [ ] **Step 1: Negative test — plugin.json has no mcpServers field**

Run: `grep -c "mcpServers" .claude-plugin/plugin.json`
Expected: `0`. Per the spec, the plugin manifest deliberately does NOT ship MCPs.

- [ ] **Step 2: Shared helper is referenced by the four affected skills**

Run:
```bash
grep -l "_shared/offer-mcp.md" skills/coding-setup/SKILL.md skills/web-development-setup/SKILL.md skills/design-setup/SKILL.md skills/office-setup/SKILL.md
```
Expected: all four files listed.

- [ ] **Step 3: Slug presence**

Run:
```bash
grep -c "\bgithub\b.*mcp\|claude mcp add github" skills/coding-setup/SKILL.md skills/web-development-setup/SKILL.md
grep -c "figma-context" skills/design-setup/SKILL.md
grep -c "gmail\|google-calendar\|google-drive" skills/office-setup/SKILL.md
```
Expected: ≥ 1 hit in each of the six target grep runs.

- [ ] **Step 4: Unchanged-skill verification**

Run: `grep -c "_shared/offer-mcp.md" skills/knowledge-base-builder/SKILL.md`
Expected: `0`. KB-builder keeps its CLI + subagent pattern.

Run: `grep -c "Obsidian CLI" skills/knowledge-base-builder/SKILL.md`
Expected: ≥ 1. Existing pattern still present.

- [ ] **Step 5: Anchor doc unchanged as source of truth**

Run: `grep -c "figma-context\|github\|gmail\|calendar\|drive" docs/anchors/mcp-servers.md`
Expected: ≥ 4. No skill should reference an MCP slug that is not mentioned in the anchor.

- [ ] **Step 6: Manual E2E — GitHub MCP in coding-setup**

In a scratch git repo with a GitHub remote:
```bash
mkdir -p /tmp/coding-setup-mcp-test && cd /tmp/coding-setup-mcp-test
git init -q && git remote add origin git@github.com:example/test.git
export GITHUB_PERSONAL_ACCESS_TOKEN=dummy  # a dummy value is fine for registration
```

In a Claude Code session pointed at this directory, invoke `/coding-setup`. Expected:
1. The GitHub MCP offer appears.
2. Choosing "yes" runs `claude mcp add github npx -- -y @modelcontextprotocol/server-github` successfully (registration succeeds even with dummy token; only tool calls need a real token).
3. Generated CLAUDE.md contains a `## Configured MCP servers` section with a `github:` bullet.
4. Re-running `/coding-setup` in the same project detects the existing registration and skips the prompt with a "Skipped github MCP offer (already registered)" log.

- [ ] **Step 7: Manual E2E — Conditional skip**

In a scratch directory with no git init:
```bash
mkdir -p /tmp/coding-setup-no-git && cd /tmp/coding-setup-no-git
```

Invoke `/coding-setup`. Expected: no GitHub MCP offer; no `## Configured MCP servers` section in generated CLAUDE.md.

- [ ] **Step 8: Manual E2E — Office Q1 gating**

Two scratch runs:
- Run 1: answer Q1 = "A) Emails and messages". Expected: Gmail and Calendar offered, Drive NOT offered.
- Run 2: answer Q1 = "B) Reports and proposals". Expected: Drive offered, Gmail and Calendar NOT offered.
- Run 3: answer Q1 = "D) All of the above". Expected: all three offered.

- [ ] **Step 9: Cross-check spec Success Criteria**

Open `docs/superpowers/specs/2026-04-21-mcp-server-integration-design.md` and tick every bullet in "Success Criteria" against the branch state. Any unmet criterion blocks the PR.

- [ ] **Step 10: Open PR**

```bash
gh pr create --title "Integrate opt-in MCP recommendations for Figma, GitHub, Gmail, Calendar, Drive" --body "$(cat <<'EOF'
## Summary

- Add shared offer-mcp helper (`skills/_shared/offer-mcp.md`) for opt-in MCP registration via `claude mcp add`
- Wire GitHub MCP offer into `coding-setup` and `web-development-setup` (gated on GitHub remote)
- Wire Figma MCP offer into `design-setup` (gated on Q1 = Figma)
- Wire Gmail/Calendar/Drive MCP offers into `office-setup` (gated on Q1 answer)
- Add `checkup` Check 4.3 surfacing unregistered recommended MCPs

Plugin manifest is NOT extended with `mcpServers` — runtime registration keeps MCPs opt-in and leaves OAuth handling to Claude Code.

## Spec

`docs/superpowers/specs/2026-04-21-mcp-server-integration-design.md`

## Test plan

- [x] Static grep: plugin.json has no `mcpServers` field
- [x] Static grep: four affected skills reference the shared helper
- [x] Static grep: knowledge-base-builder unchanged
- [x] Manual E2E: GitHub MCP offer + conditional skip on non-GitHub repo
- [x] Manual E2E: Office-setup Q1 gating of Gmail/Calendar/Drive

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review (performed at plan authoring time)

- **Spec coverage:** Every Success Criterion in the spec maps to a task. Plugin-manifest negative test → Task 7 Step 1. Shared-helper reference → Task 7 Step 2. Slug presence per skill → Task 7 Step 3. KB-builder unchanged → Task 7 Step 4. Anchor doc authority → Task 7 Step 5. Checkup Check 4.3 → Task 6. Manual E2E scenarios (GitHub yes-path, non-git skip, Office Q1 gating) → Task 7 Steps 6–8.
- **Placeholders:** No "TBD". Exact install commands for GitHub MCP are fixed in Task 2 and reused by Task 3 via cross-reference. Figma/Google install commands explicitly defer to the anchor doc because those commands are likely to evolve — the skill wiring is stable, only the exact `claude mcp add` string is anchor-sourced.
- **Consistency:** `mcp_slug` naming is consistent across Tasks 1–5 and the verification greps. Helper filename `_shared/offer-mcp.md` is used identically in Tasks 1–5 and Task 7.
- **Known soft edge:** Task 4 (Figma) and Task 5 (Google MCPs) rely on `docs/anchors/mcp-servers.md` for the exact install command. If the anchor changes, skills pick up the new command on next generation — but the implementer must verify the anchor is current at implementation time. Manual E2E Step 6 uses the stable GitHub MCP command as the primary smoke test.
- **Non-goal confirmation:** No Task touches `.claude-plugin/plugin.json`. That is verified negatively in Task 7 Step 1.
