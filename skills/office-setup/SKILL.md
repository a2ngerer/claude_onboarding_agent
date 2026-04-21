---
name: office-setup
description: Set up Claude for office and business productivity — configures your writing style, document preferences, and company context so Claude always produces on-brand, appropriately formal output.
---

# Office Setup

This skill configures Claude for business and office work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=office skill=office-setup section=claude-md -->
## Claude Onboarding Agent — Office Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: office — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users) with brainstorming and planning workflows for complex tasks." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask one at a time:

1. "What types of documents do you create most often?
   A) Emails and messages
   B) Reports and proposals
   C) Presentations
   D) All of the above / a mix"

2. "What writing style do you prefer?
   A) Formal — corporate tone, complete sentences, no contractions
   B) Semi-formal — professional but approachable
   C) Casual — conversational and direct"

3. "Is there any company, team, or project context that Claude should always keep in mind? (Optional — press Enter to skip)
   Example: 'We are a SaaS company selling to enterprise HR teams' or 'I work in legal compliance at a bank'"

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

## Step 4: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Office & Business

## Context
[Answer from Q3, or "No specific context provided."]

## Writing Style
Preferred style: [answer from Q2 — Formal / Semi-formal / Casual]
Primary document types: [answer from Q1]

## Guidelines
- Always match the preferred writing style defined above
- For emails: suggest a clear subject line when drafting; include greeting and sign-off
- For reports: use an executive summary, clear section headers, and a conclusions section
- For presentations: suggest slide structure with one idea per slide; include speaker notes when asked
- Proofread for grammar and clarity before presenting output
- If the document's audience or purpose is not clear, ask before drafting longer pieces

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For complex multi-step tasks (research + structure + write), use superpowers:brainstorming to plan the approach before drafting.

[Include ONLY if any of gmail_installed / gmail_deferred / google-calendar_installed / google-calendar_deferred / google-drive_installed / google-drive_deferred is true — emitted per skills/_shared/offer-mcp.md Step 5, one bullet per installed or deferred MCP]
## Configured MCP servers
- gmail: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
- google-calendar: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
- google-drive: [see _shared/offer-mcp.md Step 5 for the exact per-state line format]
```

### .gitignore

```gitignore
# Office temp files
~$*
*.tmp

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

## Step 5: Write Upgrade Metadata

Set `setup_slug: office`, `skill_slug: office-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 6: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: office`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: office`
   - `skill_slug: office-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

## Step 7: Completion Summary

```
✓ Office setup complete!

Files created:
  CLAUDE.md                     — writing style, document preferences, and context instructions
  .gitignore                    — office temp file rules
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

MCP servers:
  [up to three lines — one per considered MCP (gmail, google-calendar, google-drive) — formatted per skills/_shared/offer-mcp.md Step 6; omit any line whose trigger condition was false]

Next steps:
  Start a new Claude session and say: "Draft an email to [recipient] about [topic]"
  Or: "Write a report on [subject] for [audience]"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
