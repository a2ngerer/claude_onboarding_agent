# Design: Centralized Installation Protocol

**Date:** 2026-04-17
**Status:** Draft

## Problem

All 7 setup skills (coding-setup, knowledge-base-builder, office-setup, research-setup, content-creator-setup, devops-setup, design-setup) have an installation step for external dependencies (Superpowers, Karpathy Guidelines, Obsidian MCP). Currently this step:

1. Does not check if a dependency is already installed
2. Does not ask whether to install globally (`~/.claude`) or project-locally (`.claude`)
3. Duplicates similar-but-inconsistent logic across 7 files

## Goals

- Check before installing: detect already-installed dependencies and inform the user
- Ask scope first (global vs project-local), then method (marketplace vs github)
- Single source of truth: one shared protocol file, referenced by all skills

## Non-Goals

- Changing what dependencies each skill installs
- Changing the context questions or artifact generation steps
- Handling "Community skills" optional install steps (these are always new installs, no prior-check needed, and remain inline in each skill)

## Behavior Changes vs. Current

- **Required dependencies (coding-setup, knowledge-base-builder):** Today the user is asked one question (method: Marketplace or GitHub). After this change, they will be asked two — scope first, then method. This is intentional: scope is new information we now collect.
- **knowledge-base-builder:** Currently asks one shared method question for both Superpowers and Karpathy. After this change, the protocol handles each dependency independently. The user will receive separate scope+method questions per dependency.

## Design

### New file: `skills/_shared/installation-protocol.md`

A shared markdown file containing the full check-install logic. Skills read this file via the Read tool and follow it for each of their listed dependencies.

Each skill's Step 1 declares its dependencies with canonical variable names and type (required / optional / conditional). The protocol uses those names throughout.

**Canonical variable names per dependency:**

| Dependency          | `_installed` var        | `_scope` var        | `_method` var        |
|---------------------|-------------------------|---------------------|----------------------|
| Superpowers         | `superpowers_installed` | `superpowers_scope` | `superpowers_method` |
| Karpathy Guidelines | `karpathy_installed`    | `karpathy_scope`    | `karpathy_method`    |
| Obsidian MCP        | `obsidian_mcp_installed`| — (always local)    | — (always GitHub)    |

`_method` values: `marketplace` | `github`. Used in completion summaries ("installed via Plugin Marketplace / GitHub").

---

**Protocol flow per dependency:**

### Protocol Step 1: Already-installed check

- **For plugins/skills (Superpowers, Karpathy):**
  - Try `/plugin list` to detect Marketplace-installed plugins. If `/plugin list` is unavailable or fails, fall back to filesystem only.
  - Also check filesystem: `~/.claude/plugins/<name>/` (global) and `.claude/plugins/<name>/` (project-local)
  - If found by either method: inform the user ("Found [Name] already installed — skipping installation"), set `<name>_installed: true`, skip to next dependency
  - If not found: continue to Protocol Step 2

- **For MCPs (Obsidian MCP):**
  - Check `.claude/settings.json` for an existing entry under `mcpServers` with key `obsidian`
  - MCPs are always project-local; there is no global MCP scope question
  - If found: inform the user ("Found Obsidian MCP already configured — skipping"), set `obsidian_mcp_installed: true`, skip to next dependency
  - If not found: continue to Protocol Step 2

### Protocol Step 2: Opt-in / condition check

- **Required:** Skip this step entirely — proceed directly to Protocol Step 3.
- **Optional:** Ask the user "Would you like to install [Name]?" with a one-line description.
  - If no: set `<name>_installed: false`, skip to next dependency.
- **Conditional:** The skill sets a boolean variable before entering the protocol (e.g., `obsidian_mcp_condition: true/false` based on the user's answer to a context question). The protocol checks this variable: if false, set `<name>_installed: false` and skip to next dependency. The protocol does not ask an additional opt-in question for conditional dependencies.

### Protocol Step 3: Scope (plugins/skills only — MCPs skip this step, they are always project-local)

Ask: "Install [Name] globally (`~/.claude`) or project-local (`.claude`)?"

- **Global (`global`):** Marketplace and GitHub are both available → continue to Protocol Step 4
- **Local (`local`):** Only GitHub is available. Inform the user: "Project-local installs use GitHub only — the Plugin Marketplace only supports global installs." → skip Protocol Step 4, go directly to Protocol Step 5c

Store as `<name>_scope: global | local`.

### Protocol Step 4: Method (global scope only)

Ask: "Plugin Marketplace or GitHub?"

- **Marketplace:** run `/plugin install <marketplace-id>` → go to Protocol Step 5a
- **GitHub (global):** `git clone <url> ~/.claude/plugins/<name>` → go to Protocol Step 5b

Store as `<name>_method: marketplace | github`.

### Protocol Step 5: Verify

- **5a — Marketplace verify:** Check via `/plugin list` that the plugin now appears as installed. Set `<name>_method: marketplace`.
- **5b — GitHub global verify:** Check that `~/.claude/plugins/<name>/` directory exists. Set `<name>_method: github`.
- **5c — GitHub local verify:** Check that `.claude/plugins/<name>/` directory exists. Set `<name>_method: github`, `<name>_scope: local`.

On success: set `<name>_installed: true`.

On failure:
- Warn: "[Name] installation failed — setup continues without it. Install manually later."
- Set `<name>_installed: false`
- **Never block.** For required dependencies that fail, the skill's artifact generation step is responsible for omitting Superpowers-dependent content from CLAUDE.md (controlled by the `<name>_installed` flag, which is already handled in each skill's generation step).

---

### Changes to each skill

Replace the current "Step 1: Installation Method" (or "Step 1: Superpowers") with a block like this (adapt dependency list per skill):

```
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Note: for knowledge-base-builder, the Obsidian MCP dependency must be processed AFTER Step 2 (context questions), not here. Process Superpowers and Karpathy now, then return to process Obsidian MCP once the user has answered the Obsidian question in Step 2.

Dependencies (process in order):
- Superpowers (required) — marketplace-id: superpowers@claude-plugins-official, github: https://github.com/obra/superpowers
- Karpathy Guidelines (optional) — github only: https://github.com/forrestchang/andrej-karpathy-skills, name: karpathy-skills
- Obsidian MCP (conditional: obsidian_mcp_condition) — always project-local GitHub, configured via settings.json not plugin install
```

Note for `knowledge-base-builder`: The Obsidian MCP dependency is conditional on a Step 2 answer. Process Superpowers and Karpathy in Step 1, then return to process Obsidian MCP immediately after the user answers the Obsidian question in Step 2.

### Dependency reference table

| Skill                  | Superpowers | Karpathy | Obsidian MCP |
|------------------------|-------------|----------|--------------|
| coding-setup           | required    | —        | —            |
| knowledge-base-builder | required    | optional | conditional  |
| office-setup           | optional    | —        | —            |
| research-setup         | optional    | —        | —            |
| content-creator-setup  | optional    | —        | —            |
| devops-setup           | optional    | —        | —            |
| design-setup           | optional    | —        | —            |

Community skills optional install steps are out of scope for this protocol and remain inline in each skill.

## Implementation Plan

1. Create `skills/_shared/installation-protocol.md` with the full protocol text above
2. Update Step 1 in all 7 skill files to reference the protocol and declare their dependency list
   - `knowledge-base-builder` is the most complex: 3 dependencies, Obsidian MCP deferred to after Step 2
   - All other skills: 1 dependency (Superpowers), straightforward
3. Remove now-redundant inline installation logic from each skill
4. Smoke-test each skill by tracing through the new Step 1 manually with:
   - (a) dependency already installed → should skip with notification
   - (b) fresh install, global scope, Marketplace method → should ask scope then method
   - (c) fresh install, global scope, GitHub method → should ask scope then method
   - (d) fresh install, local scope → should skip method question, clone to .claude/
   - (e) installation failure → should warn and continue, never block
