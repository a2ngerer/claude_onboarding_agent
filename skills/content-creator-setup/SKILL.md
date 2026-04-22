---
name: content-creator-setup
description: Set up Claude for content creation — configures your brand voice, target platforms, and audience so Claude helps you write scripts, posts, newsletters, and ideas that sound authentically like you.
---

# Content Creator Setup

This skill configures Claude for content creation work.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=content-creator skill=content-creator-setup section=claude-md -->
## Claude Onboarding Agent — Content Creator Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: content-creator — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). The brainstorming skill is useful for generating content ideas and exploring different angles." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask one at a time:

1. "Which platforms do you primarily create content for?
   A) YouTube (long-form video)
   B) Instagram / TikTok (short-form)
   C) Newsletter / blog
   D) Podcast
   E) Multiple / all of the above"

2. "How would you describe your brand voice? Be as specific as possible — the more detail, the better Claude will match your style.
   Examples: 'educational but casual, like explaining things to a smart friend', 'professional thought leader in fintech', 'funny and irreverent tech commentary', 'warm and personal wellness content'"

3. "Who is your target audience? (e.g., 'developers aged 25–40 interested in AI tools', 'small business owners with no tech background', 'fitness enthusiasts looking for quick workouts')"

## Step 3: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Content Creation

## Brand
Platform(s): [answer from Q1]
Brand voice: [answer from Q2]
Target audience: [answer from Q3]

## Guidelines
- Always write in the brand voice defined above — never sound generic or like a typical AI
- Before writing, ask yourself: would [target audience] find this valuable and engaging?
- For YouTube scripts: Hook (first 30 seconds to grab attention), problem setup, solution or story, call to action
- For short-form (Instagram/TikTok): Hook in the very first line, one single idea per post, strong ending or question to drive engagement
- For newsletters: Compelling subject line, personal or story-based opener, one core idea with clear takeaway, simple call to action
- For podcasts: Conversational tone, natural transitions, questions to guide discussion
- When repurposing content: adapt format and length for the target platform — never copy-paste across formats
- When given a topic, suggest multiple content angles, not just one
- If the requested content doesn't clearly fit the brand voice, flag it and offer alternatives

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For ideation sessions and planning content series, use superpowers:brainstorming to explore angles before committing to a direction.
```

### .gitignore

```gitignore
# Large media files
*.mp4
*.mov
*.avi
*.psd
*.ai
*.sketch
*.fig

# OS
.DS_Store
Thumbs.db

# Claude local settings
.claude/settings.local.json
```

## Step 4: Write Upgrade Metadata

Set `setup_slug: content-creator`, `skill_slug: content-creator-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 5: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: content-creator`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: content-creator`
   - `skill_slug: content-creator-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

For every call, also capture `render_freshness`. When it is anything other than `network` or `cache` (i.e. `fallback` or `embedded`), record the `(anchor_slug, render_freshness)` pair in `anchor_freshness_notes`. The completion summary's `Anchor freshness` line consumes this list.

## Step 6: Completion Summary

```
✓ Content Creator setup complete!

Files created:
  CLAUDE.md                     — brand voice, platform preferences, and audience instructions
  .gitignore                    — large media file rules
  .claude/onboarding-meta.json  — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per entry:
   Anchor <anchor_slug> served from <render_freshness> — consider running /anchors to refresh.]

Next steps:
  Start a new Claude session and say: "Give me 5 content ideas about [your topic]"
  Or: "Write a YouTube script about [topic] in my brand voice"
  Or: "Turn this blog post into an Instagram caption: [paste content]"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
