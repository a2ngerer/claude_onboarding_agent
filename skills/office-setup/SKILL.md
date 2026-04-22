---
name: office-setup
description: Set up Claude for business writing — emails, memos, reports, proposals. Configures writing style, document-type preferences, and company context so Claude produces on-brand text. Does NOT cover presentations or slide decks.
---

# Office Setup

This skill configures Claude for business writing (emails, memos, reports, proposals). Presentations and slide decks are explicitly out of scope — the emitted rules commit to written prose only.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=office skill=office-setup section=claude-md -->
## Claude Onboarding Agent — Office Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: office — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users) with brainstorming and planning workflows for complex tasks." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask one at a time:

1. "Which type of business writing do you produce most often?
   A) Emails and short messages (customer replies, internal updates, memos)
   B) Reports and proposals (longer, structured, audience-facing)
   C) A mix of both"

   Store the letter as `document_focus`. This answer branches the emitted guidelines in Step 4 and gates the Google-Drive MCP offer in Step 3.

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
- `trigger_condition`: `document_focus` is `A` or `C` (email path or mix).
- `capability_line`: "Read, search, and send email from your Gmail inbox."
- `install_command`: the current install command from `docs/anchors/mcp-servers.md` under "Productivity" (prefer the official Google Gmail MCP if listed; else the community `gmail-mcp-server` noted in the anchor).
- `auth_type`: `oauth`
- `auth_detail`: "Google OAuth — reads your Gmail inbox per the scopes shown on the consent screen."
- `pointer_link`: see anchor doc.

### Google Calendar

- `mcp_slug`: `google-calendar`
- `trigger_condition`: same as Gmail (`document_focus` is `A` or `C`). Offer Calendar only if Gmail was offered.
- `capability_line`: "Read and create calendar events."
- `install_command`: from `docs/anchors/mcp-servers.md`.
- `auth_type`: `oauth`
- `auth_detail`: "Google OAuth — reads/writes your Google Calendar per the consent screen scopes."
- `pointer_link`: see anchor doc.

### Google Drive

- `mcp_slug`: `google-drive`
- `trigger_condition`: `document_focus` is `B` or `C` (report path or mix).
- `capability_line`: "Read and search documents in your Google Drive."
- `install_command`: from `docs/anchors/mcp-servers.md`.
- `auth_type`: `oauth`
- `auth_detail`: "Google OAuth — reads your Google Drive per the consent screen scopes."
- `pointer_link`: see anchor doc.

Record `gmail_installed`, `google-calendar_installed`, `google-drive_installed` in skill state.

## Step 4: Generate Artifacts

### CLAUDE.md

Assemble the template below. The `## Guidelines` section has a shared header block plus one or two branched subheadings keyed on `document_focus`:

- `document_focus: A` → emit only the `### Emails and short messages` subheading.
- `document_focus: B` → emit only the `### Reports and proposals` subheading.
- `document_focus: C` → emit both subheadings in the order shown.

```markdown
# Claude Instructions — Business Writing

## Context
[Answer from Q3, or "No specific context provided."]

## Writing Style
Preferred style: [answer from Q2 — Formal / Semi-formal / Casual]
Primary document focus: [answer from Q1 — Emails / Reports / Mix]

## Guidelines
- Always match the preferred writing style defined above
- Proofread for grammar and clarity before presenting output
- If the document's audience or purpose is not clear, ask before drafting longer pieces

[Include this subheading ONLY if document_focus is A or C]
### Emails and short messages
- Suggest a clear, specific subject line when drafting a new email — not a generic "Follow-up" or "Update"
- Open with an appropriate greeting and close with a sign-off that matches the preferred style
- Keep paragraphs short (2–4 sentences) and put the main ask in the first paragraph
- One primary ask per message; if more are needed, use a short bulleted list and label them
- For replies: mirror the sender's register unless the style above overrides it; quote the specific point you are answering

[Include this subheading ONLY if document_focus is B or C]
### Reports and proposals
- Open with an executive summary that states the purpose, the key finding or recommendation, and the required decision
- Use clear section headers; structure follows problem → analysis → options → recommendation → next steps
- Cite numbers and sources inline; do not drop claims without evidence the reader can verify
- Close with a conclusions section that re-states the recommendation and the owner / timeline for the next step
- Match length to audience: an internal memo is shorter than a board proposal; ask if the audience is unclear

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For longer reports and proposals, use superpowers:brainstorming to structure the argument before drafting, and superpowers:writing-plans for multi-section revisions.

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

For every call, also capture `render_freshness`. When it is anything other than `network` or `cache` (i.e. `fallback` or `embedded`), record the `(anchor_slug, render_freshness)` pair in `anchor_freshness_notes`. The completion summary's `Anchor freshness` line consumes this list.

## Step 7: Completion Summary

```
✓ Business writing setup complete!

Scope: emails, memos, reports, proposals. Presentations are NOT covered —
re-run `/onboarding` if you need a separate skill for slide decks.

Files created:
  CLAUDE.md                     — writing style, document-focus guidelines, and context
  .gitignore                    — office temp file rules
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

MCP servers:
  [up to three lines — one per considered MCP (gmail, google-calendar, google-drive) — formatted per skills/_shared/offer-mcp.md Step 6; omit any line whose trigger condition was false]

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per entry:
   Anchor <anchor_slug> served from <render_freshness> — consider running /anchors to refresh.]

Next steps:
  [If document_focus is A or C] Start a new Claude session and say: "Draft an email to [recipient] about [topic]"
  [If document_focus is B or C] Or: "Draft an executive summary and section outline for a proposal on [subject] to [audience]"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
