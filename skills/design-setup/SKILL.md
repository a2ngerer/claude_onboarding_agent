---
name: design-setup
description: Set up Claude for UI/UX design work — configures your design tool, frontend stack, and accessibility standard so Claude generates production-quality components and avoids generic AI aesthetics.
---

# UI/UX Design Setup

This skill configures Claude for UI/UX design and frontend work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=design skill=design-setup section=claude-md -->
## Claude Onboarding Agent — Design Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: design — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). The brainstorming skill is useful for exploring design directions and component structures before committing to an implementation." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask one at a time:

1. "Which design tool do you primarily use?
   A) Figma
   B) Sketch
   C) Adobe XD
   D) Other — please specify"

2. "What is your frontend stack?
   A) React + Tailwind CSS
   B) Vue
   C) Vanilla CSS / plain HTML
   D) Other — please specify
   E) None — I work design-only, no code"

3. "What is your primary workflow with Claude?
   A) Hand off designs → have Claude generate the code
   B) Review and improve existing UI code
   C) Both"

4. "Which accessibility standard should Claude enforce?
   A) WCAG AA (standard compliance)
   B) WCAG AAA (strict compliance)
   C) No specific standard"

## Step 3: Optional Community Skills

> "Would you like to install additional community skills?
>
> A) frontend-design (official Anthropic) — avoids AI-generic UI, makes bold design decisions (277k installs, strongly recommended)
> B) web-artifacts-builder — build complex HTML artifacts with React + Tailwind + shadcn/ui
> C) accessibility-skill — automated WCAG audit and remediation guidance
> D) All of the above
> E) None"

For each selected skill, run: `/plugin install <skill>@claude-plugins-official`

On failure: warn and continue. Store successfully installed skills as `optional_skills_installed`.

## Step 4: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — UI/UX Design

## Design Context
Tool: [Q1 answer] | Stack: [Q2 answer] | Workflow: [Q3 answer] | Accessibility: [Q4 answer]

## Guidelines
- Avoid generic AI aesthetics — no default gray cards, no rounded-everything, no "modern minimal" clichés unless explicitly requested
- Always check [Q4 accessibility standard] compliance for color contrast and interactive elements
- When generating UI code: component-first, no inline styles, use design tokens where available
- When reviewing designs or code: flag accessibility issues before aesthetic feedback
- Prefer existing component library patterns over custom implementations
- For Figma handoff: extract exact spacing, typography, and color tokens from the provided specs — do not approximate
- When given a topic or feature, suggest multiple visual directions before committing to one

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For design exploration and component planning, use superpowers:brainstorming to compare directions before generating code.
```

Adapt based on Q2 (stack):
- React + Tailwind → add "Prefer Tailwind utility classes over custom CSS. Use shadcn/ui components where applicable."
- Vue → add "Prefer Vue SFC patterns. Use Vuetify or PrimeVue components where applicable."
- None (design-only) → omit code-specific guidelines

### AGENTS.md

```markdown
# Agent Roles

## designer
Generates UI components and layouts from design specs or descriptions. Follows the design system and accessibility standard defined in CLAUDE.md. Never introduces inline styles or undocumented design tokens.

## accessibility-auditor
Reviews UI code and designs for WCAG compliance. Returns a prioritized list of violations with remediation suggestions, ordered by severity.
```

### .claude/settings.json

Build based on Q2 (frontend stack):
- React + Tailwind or Vue → include npm/npx/node:
```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)"
    ]
  }
}
```
- Other: treat same as React + Tailwind (include npm/npx/node) as a safe default for unknown stacks
- None (design-only) or Vanilla CSS:
```json
{
  "permissions": {
    "allow": ["Bash(git *)"]
  }
}
```

### .gitignore

```gitignore
# Design files
*.fig
*.sketch

# Frontend build
node_modules/
dist/
.next/

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

## Step 5: Write Upgrade Metadata

Set `setup_slug: design`, `skill_slug: design-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 6: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: design`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: design`
   - `skill_slug: design-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

## Step 7: Completion Summary

```
✓ UI/UX Design setup complete!

Files created:
  CLAUDE.md                     — design context, accessibility standard ([Q4]), UI guidelines
  AGENTS.md                     — designer and accessibility-auditor role definitions
  .claude/settings.json         — tool permissions for [stack]
  .gitignore                    — design file and build rules
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Optional community skills: [list of installed skills, or "none selected"]

Next steps:
  Start a new Claude session and paste a design description or Figma spec.
  Example: "Build this card component: [description or paste Figma spec]"
  Example: "Review this UI for WCAG AA compliance"
  Example: "Redesign this form — it feels too generic"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
