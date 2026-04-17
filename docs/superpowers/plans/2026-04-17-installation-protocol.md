# Installation Protocol Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace inline installation logic in all 7 setup skills with a shared `skills/_shared/installation-protocol.md` that checks for existing installs, asks global vs project-local scope, then method.

**Architecture:** One new shared protocol file read via the Read tool. Each skill's Step 1 is rewritten to reference it and declare its dependencies. For `coding-setup`, the now-redundant Step 3 (install) is removed and step numbers shifted. For `knowledge-base-builder`, Superpowers + Karpathy are processed in Step 1, Obsidian MCP is deferred to after Step 2.

**Tech Stack:** Markdown skill files only — no code. All changes are text edits.

**Spec:** `docs/superpowers/specs/2026-04-17-installation-protocol-design.md`

---

## File Map

| Action | Path | What changes |
|--------|------|--------------|
| Create | `skills/_shared/installation-protocol.md` | New shared protocol |
| Modify | `skills/coding-setup/SKILL.md` | Rewrite Step 1, remove Step 3, renumber Steps 4–6 → 3–5 |
| Modify | `skills/knowledge-base-builder/SKILL.md` | Rewrite Step 1 (Superpowers+Karpathy), add Obsidian MCP trigger after Step 2 Q2, remove Step 3 install block |
| Modify | `skills/office-setup/SKILL.md` | Rewrite Step 1 |
| Modify | `skills/research-setup/SKILL.md` | Rewrite Step 1 |
| Modify | `skills/content-creator-setup/SKILL.md` | Rewrite Step 1 |
| Modify | `skills/devops-setup/SKILL.md` | Rewrite Step 1 |
| Modify | `skills/design-setup/SKILL.md` | Rewrite Step 1 |

---

## Task 1: Create the shared installation protocol

**Files:**
- Create: `skills/_shared/installation-protocol.md`

- [ ] **Step 1: Create the file**

Create `skills/_shared/installation-protocol.md` with this exact content:

```markdown
# Installation Protocol

This file is read by setup skills during their dependency installation step.
The calling skill declares which dependencies to install and their types.
Follow this protocol for each dependency in the declared order.

## Dependency Types

- **required** — always install; skip opt-in question
- **optional** — ask the user if they want it before proceeding
- **conditional** — gated on a boolean variable set by the skill before this protocol runs; skip if the condition is false; skip opt-in question

## Protocol Steps (run for each dependency in order)

### Step P1: Already-installed check

For plugins/skills (Superpowers, Karpathy Guidelines):
- Run `/plugin list` if available; check whether the plugin appears as installed. If `/plugin list` is unavailable or errors, fall back to filesystem check only.
- Also check filesystem: `~/.claude/plugins/<name>/` (global) and `.claude/plugins/<name>/` (project-local)
- If found by either method:
  - Tell the user: "Found [Name] already installed — skipping installation."
  - Set `<name>_installed: true`
  - Skip to next dependency

For MCPs (Obsidian MCP):
- Check `.claude/settings.json` for an existing entry under `mcpServers` with key `obsidian`
- If found:
  - Tell the user: "Found Obsidian MCP already configured — skipping."
  - Set `obsidian_mcp_installed: true`
  - Skip to next dependency

### Step P2: Opt-in / condition check

- **required**: skip this step, proceed to Step P3
- **optional**: ask "Would you like to install [Name]?" with a one-line description
  - If no: set `<name>_installed: false`, skip to next dependency
- **conditional**: check the boolean variable set by the skill (e.g. `obsidian_mcp_condition`)
  - If false: set `<name>_installed: false`, skip to next dependency
  - If true: proceed to Step P3

### Step P3: Scope (plugins/skills only — MCPs always skip to Step P5c)

Ask: "Install [Name] globally (`~/.claude`) or project-local (`.claude`)?"

- **global**: Marketplace and GitHub are both available → proceed to Step P4
- **local**: Only GitHub is available. Tell the user: "Project-local installs use GitHub only — the Plugin Marketplace only supports global installs." → skip Step P4, go to Step P5b

Store as `<name>_scope: global | local`.

### Step P4: Method (global scope only)

Ask: "Plugin Marketplace or GitHub?"

- **Marketplace**: run `/plugin install <marketplace-id>` → go to Step P5a
- **GitHub (global)**: `git clone <url> ~/.claude/plugins/<name>` → go to Step P5b

Store as `<name>_method: marketplace | github`.

### Step P5: Verify

- **P5a — Marketplace**: check via `/plugin list` that the plugin now appears. Set `<name>_method: marketplace`.
- **P5b — GitHub global**: check that `~/.claude/plugins/<name>/` exists. Set `<name>_method: github`, `<name>_scope: global`.
- **P5c — GitHub local**: `git clone <url> .claude/plugins/<name>`. Check that `.claude/plugins/<name>/` exists. Set `<name>_method: github`, `<name>_scope: local`.

On success: set `<name>_installed: true`.

On failure:
- Warn: "⚠ [Name] installation failed — setup continues without it. Install manually later."
- Set `<name>_installed: false`
- Never block — continue to the next dependency or the next skill step.

## Variable Reference

| Dependency          | `_installed`             | `_scope`            | `_method`            |
|---------------------|--------------------------|---------------------|----------------------|
| Superpowers         | `superpowers_installed`  | `superpowers_scope` | `superpowers_method` |
| Karpathy Guidelines | `karpathy_installed`     | `karpathy_scope`    | `karpathy_method`    |
| Obsidian MCP        | `obsidian_mcp_installed` | — (always local)    | — (always GitHub)    |
```

- [ ] **Step 2: Commit**

```bash
git add skills/_shared/installation-protocol.md
git commit -m "feat: add shared installation protocol"
```

---

## Task 2: Update coding-setup

**Files:**
- Modify: `skills/coding-setup/SKILL.md`

Current structure: Step 1 (ask method) → Step 2 (context) → Step 3 (install) → Step 4 (artifacts) → Step 5 (community skills) → Step 6 (summary)

New structure: Step 1 (protocol) → Step 2 (context) → Step 3 (artifacts) → Step 4 (community skills) → Step 5 (summary)

- [ ] **Step 1: Replace Step 1**

Replace the entire `## Step 1: Installation Method` section (lines 14–23) with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (required) — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
```

- [ ] **Step 2: Remove Step 3 (install block) and renumber**

Delete the entire `## Step 3: Install Superpowers` section (lines 34–54).

Renumber remaining steps:
- `## Step 4: Generate Artifacts` → `## Step 3: Generate Artifacts`
- `## Step 5: Optional Community Skills` → `## Step 4: Optional Community Skills`
- `## Step 6: Completion Summary` → `## Step 5: Completion Summary`

- [ ] **Step 3: Update completion summary to use new variables**

In the new Step 5 completion summary, replace:
```
  [✓ Superpowers installed via Plugin Marketplace / GitHub]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]
```
with:
```
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]
```

- [ ] **Step 4: Commit**

```bash
git add skills/coding-setup/SKILL.md
git commit -m "feat: use shared installation protocol in coding-setup"
```

---

## Task 3: Update knowledge-base-builder

**Files:**
- Modify: `skills/knowledge-base-builder/SKILL.md`

Current structure: Step 1 (ask method for both) → Step 2 (context, includes Obsidian Q) → Step 3 (install all three) → Step 4 (artifacts) → Step 5 (summary)

New structure: Step 1 (protocol: Superpowers + Karpathy) → Step 2 (context, Obsidian Q triggers protocol for MCP) → Step 3 (artifacts) → Step 4 (summary)

- [ ] **Step 1: Replace Step 1**

Replace the entire `## Step 1: Installation Method` section with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Note: Process Superpowers and Karpathy Guidelines here. The Obsidian MCP is conditional on the user's answer in Step 2 — process it immediately after Step 2, question 2.

Dependencies:
- Superpowers (required) — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
- Karpathy Guidelines (optional) — github only: `https://github.com/forrestchang/andrej-karpathy-skills`, name: `karpathy-skills`
```

- [ ] **Step 2: Add Obsidian MCP trigger after Step 2, question 2**

In Step 2, after question 2 (the Obsidian question), add:

```markdown
   After the user answers question 2: if they chose Option A (Obsidian), immediately run the installation protocol for:
   - Obsidian MCP (conditional: true — always project-local, configured via settings.json not plugin install)
     - Already-installed check: look for `obsidian` key in `.claude/settings.json` under `mcpServers`
     - If not found: add the following to `.claude/settings.json`:
       ```json
       {
         "mcpServers": {
           "obsidian": {
             "command": "npx",
             "args": ["-y", "mcp-obsidian", "[vault_path_from_question_3]"]
           }
         }
       }
       ```
     - Set `obsidian_mcp_installed: true` on success, `false` on failure
```

- [ ] **Step 3: Remove Step 3 (install block) and renumber**

Delete the entire `## Step 3: Install Dependencies` section (the one with the install commands for Superpowers, Karpathy, and Obsidian MCP).

Renumber:
- `## Step 4: Generate Artifacts` → `## Step 3: Generate Artifacts`
- `## Step 5: Completion Summary` → `## Step 4: Completion Summary`

- [ ] **Step 4: Update completion summary**

In the new Step 4 completion summary, update the external skills lines:
```
  [✓/⚠] Superpowers [via superpowers_method (superpowers_scope) / failed — install manually]
  [✓/⚠] Karpathy Guidelines [via karpathy_method (karpathy_scope) / failed — optional, skipped]
```

- [ ] **Step 5: Commit**

```bash
git add skills/knowledge-base-builder/SKILL.md
git commit -m "feat: use shared installation protocol in knowledge-base-builder"
```

---

## Task 4: Update the 5 remaining skills (office, research, content-creator, devops, design)

These 5 skills all follow the same pattern: Step 1 = optional Superpowers with combined opt-in+method question (A/B/C). Replace with the protocol reference.

**Files:**
- Modify: `skills/office-setup/SKILL.md`
- Modify: `skills/research-setup/SKILL.md`
- Modify: `skills/content-creator-setup/SKILL.md`
- Modify: `skills/devops-setup/SKILL.md`
- Modify: `skills/design-setup/SKILL.md`

For each of the 5 skills:

- [ ] **Step 1: Replace Step 1 in office-setup**

Replace the entire `## Step 1: Superpowers (Optional)` section in `skills/office-setup/SKILL.md` with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users) with brainstorming and planning workflows for complex tasks." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
```

- [ ] **Step 2: Replace Step 1 in research-setup**

Replace the entire `## Step 1: Superpowers (Optional)` section in `skills/research-setup/SKILL.md` with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Brainstorming and planning skills work well for structuring research arguments and planning complex documents." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
```

- [ ] **Step 3: Replace Step 1 in content-creator-setup**

Replace the entire `## Step 1: Superpowers (Optional)` section in `skills/content-creator-setup/SKILL.md` with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). The brainstorming skill is useful for generating content ideas and exploring different angles." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
```

- [ ] **Step 4: Replace Step 1 in devops-setup**

Replace the entire `## Step 1: Superpowers (Optional)` section in `skills/devops-setup/SKILL.md` with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). Planning and subagent skills work well for infrastructure tasks that need careful step-by-step execution." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
```

- [ ] **Step 5: Replace Step 1 in design-setup**

Replace the entire `## Step 1: Superpowers (Optional)` section in `skills/design-setup/SKILL.md` with:

```markdown
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). The brainstorming skill is useful for exploring design directions and component structures before committing to an implementation." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`
```

- [ ] **Step 6: Update completion summaries in all 5 skills**

In each of the 5 skill files, find the completion summary's external skills block. It currently reads (one of two variants):
```
  [✓ Superpowers installed via Plugin Marketplace / GitHub]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]
```

Replace with:
```
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]
```

- [ ] **Step 7: Commit all 5**

```bash
git add skills/office-setup/SKILL.md skills/research-setup/SKILL.md skills/content-creator-setup/SKILL.md skills/devops-setup/SKILL.md skills/design-setup/SKILL.md
git commit -m "feat: use shared installation protocol in office, research, content-creator, devops, design skills"
```

---

## Smoke Test Checklist

For each skill, trace through Step 1 mentally with these cases. No automated tests exist — this is a markdown skill, so verification is manual trace:

- [ ] **Already installed**: Superpowers found at `~/.claude/plugins/superpowers/` → skill says "Found already installed — skipping" and sets `superpowers_installed: true`
- [ ] **Fresh install, global, Marketplace**: protocol asks scope ("global") → asks method ("Marketplace") → runs `/plugin install superpowers@claude-plugins-official` → verifies → sets `superpowers_installed: true`, `superpowers_method: marketplace`, `superpowers_scope: global`
- [ ] **Fresh install, global, GitHub**: protocol asks scope ("global") → asks method ("GitHub") → clones to `~/.claude/plugins/superpowers` → verifies → sets `superpowers_installed: true`, `superpowers_method: github`, `superpowers_scope: global`
- [ ] **Fresh install, local**: protocol asks scope ("local") → tells user Marketplace is global-only → clones to `.claude/plugins/superpowers` → verifies → sets `superpowers_installed: true`, `superpowers_method: github`, `superpowers_scope: local`
- [ ] **Installation failure**: clone fails → warns user → sets `superpowers_installed: false` → continues to context questions
- [ ] **knowledge-base-builder, Obsidian MCP already configured**: after Step 2 Q2 (user picks Obsidian), protocol checks `.claude/settings.json` → finds `obsidian` key → says "Found Obsidian MCP already configured — skipping"
