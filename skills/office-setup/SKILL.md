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

## Step 3: Generate Artifacts

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

## Step 4: Write Upgrade Metadata

Set `setup_slug: office`, `skill_slug: office-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 5: Completion Summary

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

Next steps:
  Start a new Claude session and say: "Draft an email to [recipient] about [topic]"
  Or: "Write a report on [subject] for [audience]"
```
