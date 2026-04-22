---
name: design-setup
description: Set up Claude for UI/UX design tooling — wires up your design tool (Figma, Sketch, XD, Penpot) and the Figma MCP handoff. Pair with web-development-setup for the frontend stack, testing, and accessibility rules.
---

# UI/UX Design Setup

This skill configures the **design-tool layer** only: which design tool the user works in, and whether Claude should read Figma frames directly via MCP for UI handoff. It intentionally does NOT configure a frontend stack, a testing setup, or accessibility rules — those live in `web-development-setup` and would duplicate rules if emitted here.

Run `web-development-setup` first (or alongside) when you also need framework-aware tool permissions, component / API conventions, or WCAG enforcement. `web-development-setup` offers to delegate to this skill automatically after it asks for the frontend framework.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=design skill=design-setup section=claude-md -->
## Claude Onboarding Agent — Design Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: design — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Delegated Mode

This skill may be invoked as a sub-step of `web-development-setup` (the "UI/design tooling" branch of web-dev Step 3b). When that happens, the parent skill sets `delegated_from: web-development-setup` in the handoff context. In delegated mode:

- Skip the language detection preamble — use the parent's `detected_language`.
- Skip Step 1 (Superpowers offer) — the parent already handled it.
- Skip Step 4 (frontend-design skill pointer) — the parent owns that prompt once.
- Skip Step 6 (Write Upgrade Metadata) and Step 7 (Render Anchor Sections) — the parent's meta file and anchor block already covers this run. Instead, append `"design-setup"` to the parent's `skills_used[]` list when it writes the meta file.

All other steps still run so the user gets the design-tool CLAUDE.md section and the Figma MCP offer.

## Step 1: Install Dependencies

Skip in delegated mode.

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). The brainstorming skill is useful for exploring design directions and component structures before committing to an implementation." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Question

Ask:

1. "Which design tool do you primarily use?
   A) Figma
   B) Sketch
   C) Adobe XD
   D) Penpot
   E) None — I mainly work from written specs or screenshots
   F) Other — please specify"

Record the answer as `design_tool`.

## Step 3: Offer Figma MCP (conditional)

Read `skills/_shared/offer-mcp.md` and follow it with these parameters:

- `mcp_slug`: `figma-context`
- `trigger_condition`: `design_tool` is "A) Figma". If the user picked another tool, skip this step entirely.
- `capability_line`: "Read Figma frames directly into Claude's context for UI-to-code handoff."
- `install_command`: the install command from `docs/anchors/mcp-servers.md` under "Design" (currently: see https://github.com/GLips/Figma-Context-MCP — use the README's documented `claude mcp add` form at registration time; adapt if the anchor is updated).
- `auth_type`: `api_token`
- `auth_detail`: `FIGMA_API_TOKEN` (generate at https://www.figma.com/developers/api#access-tokens — scope: read-only is sufficient)
- `pointer_link`: `https://github.com/GLips/Figma-Context-MCP`

Record `figma-context_installed` in skill state.

## Step 4: Offer frontend-design Skill

Skip in delegated mode — the parent skill owns this prompt.

Ask ONCE (adapt to detected language):

> "Install the official Anthropic `frontend-design` skill? It avoids AI-generic UI, makes bold design decisions, and is strongly recommended for design-to-code work (277k+ installs). (yes / no)"

On `yes`: run `/plugin install frontend-design@claude-plugins-official`. On failure: warn once and continue. Record `frontend-design_installed` accordingly.

## Step 5: Generate Artifacts

### CLAUDE.md

Emit a short, focused block — design-tool pipeline and MCP pointer only. Do NOT emit framework, workflow, or WCAG rules here; those belong to `web-development-setup`.

```markdown
# Claude Instructions — Design Tooling

## Design Tool
Primary tool: [design_tool answer]

## Design-to-Code Handoff
- When given a design spec (link, screenshot, or pasted frame), extract exact spacing, typography, and color tokens — do not approximate.
- Prefer existing component library patterns over custom reimplementations.
- If the repo has frontend conventions (see `.claude/rules/component-structure.md` when `web-development-setup` has also run), follow them before applying design-tool defaults.

[Include ONLY if superpowers_installed is true AND not in delegated mode]
## Superpowers
Superpowers is installed. For design exploration and component planning, use `superpowers:brainstorming` to compare directions before generating code.

[Include ONLY if figma-context_installed is true OR figma-context_deferred is true — emitted per skills/_shared/offer-mcp.md Step 5]
## Configured MCP servers
- figma-context: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
```

### .gitignore

Append (or extend the existing delimited block) with design-tool artifacts only. Framework build output (`node_modules/`, `.next/`, etc.) is `web-development-setup`'s responsibility — do NOT re-emit it here.

```gitignore
# Design files
*.fig
*.sketch

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

Note: this skill does NOT generate `AGENTS.md` or `.claude/settings.json`. Frontend code review, accessibility auditing, and Bash permissions for a web stack are owned by `web-development-setup` and would duplicate rules if emitted from here.

## Step 6: Write Upgrade Metadata

Skip in delegated mode.

Set `setup_slug: design`, `skill_slug: design-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 7: Render Anchor Sections

Skip in delegated mode — the parent skill's anchor pass already covers this run.

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: design`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: design`
   - `skill_slug: design-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

## Step 8: Completion Summary

```
✓ UI/UX Design setup complete!

Files created / updated:
  CLAUDE.md                     — design-tool pipeline + Figma MCP pointer (delimited section)
  .gitignore                    — design-file ignore block (delimited section)
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup                       [skipped in delegated mode]

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]                  [skipped in delegated mode]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]
  [✓ frontend-design installed | — declined | ⚠ install failed]                         [skipped in delegated mode]

MCP servers:
  [one line per MCP considered, formatted per skills/_shared/offer-mcp.md Step 6 — omit if figma-context trigger condition was false]

Next steps:
  - If you also need frontend stack rules (framework, testing, linting, WCAG), run `/web-development-setup`.
  - Paste a Figma frame or design description into a new Claude session and ask for the component implementation.
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
