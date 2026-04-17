# Design: Centralized Installation Protocol

**Date:** 2026-04-17
**Status:** Approved

## Problem

All 7 setup skills (coding-setup, knowledge-base-builder, office-setup, research-setup, content-creator-setup, devops-setup, design-setup) have an installation step for external dependencies (Superpowers, Karpathy Guidelines, Obsidian MCP, community skills). Currently this step:

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

## Design

### New file: `skills/_shared/installation-protocol.md`

A shared markdown file containing the full check-install logic. Skills read this file via the Read tool and follow it for each of their dependencies.

**Protocol flow per dependency:**

1. **Already-installed check**
   - For plugins/skills: check `~/.claude/plugins/<name>/` (global) and `.claude/plugins/<name>/` (project-local)
   - For MCPs: check for an existing entry in `.claude/settings.json` or `~/.claude/settings.json`
   - If found anywhere: inform the user ("✓ [Name] already found at [path] — skipping installation") and set `<name>_installed: true`, skip to next dependency
   - If not found: continue

2. **Opt-in** (optional dependencies only)
   - Ask: "Would you like to install [Name]?" (with brief description)
   - If no: set `<name>_installed: false`, skip to next dependency

3. **Scope**
   - Ask: "Install [Name] globally (`~/.claude`) or project-local (`.claude`)?"
   - Store as `<name>_scope: global | local`

4. **Method**
   - If `global`: ask "Plugin Marketplace or GitHub?"
     - Marketplace: run `/plugin install <marketplace-id>`
     - GitHub: `git clone <url> ~/.claude/plugins/<name>`
   - If `local`: always GitHub — `git clone <url> .claude/plugins/<name>`

5. **Verify**
   - Check the expected path exists after installation
   - On failure: warn ("⚠ [Name] installation failed — setup continues without it"), set `<name>_installed: false`, never block

### Changes to each skill

Replace the current "Step 1: Installation Method" (or "Step 1: Superpowers") with:

```
## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (required | optional)
- Karpathy Guidelines (optional) — knowledge-base-builder only
- Obsidian MCP (conditional on user answer in Step 2) — knowledge-base-builder only
```

Required vs optional is set per-skill. `coding-setup` and `knowledge-base-builder` treat Superpowers as required (no opt-in question). All other skills treat it as optional.

### Dependency reference table

| Skill                  | Superpowers | Karpathy | Obsidian MCP | Community Skills |
|------------------------|-------------|----------|--------------|-----------------|
| coding-setup           | required    | —        | —            | optional (step) |
| knowledge-base-builder | required    | optional | conditional  | —               |
| office-setup           | optional    | —        | —            | —               |
| research-setup         | optional    | —        | —            | optional (step) |
| content-creator-setup  | optional    | —        | —            | —               |
| devops-setup           | optional    | —        | —            | optional (step) |
| design-setup           | optional    | —        | —            | optional (step) |

Note: "Community skills" optional steps use a separate question later in the flow and are not part of this protocol (they are always new installs with no prior-install check needed).

## Implementation Plan

1. Create `skills/_shared/installation-protocol.md`
2. Update Step 1 in all 7 skill files to reference the protocol
3. Remove now-redundant inline installation logic from each skill
