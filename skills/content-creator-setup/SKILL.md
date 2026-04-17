---
name: content-creator-setup
description: Set up Claude for content creation — configures your brand voice, target platforms, and audience so Claude helps you write scripts, posts, newsletters, and ideas that sound authentically like you.
---

# Content Creator Setup

This skill configures Claude for content creation work.

**Language:** Use `detected_language` from handoff context, or detect from the user's first message and use it throughout.

**Existing CLAUDE.md:** If `existing_claude_md: true` in handoff context, or if CLAUDE.md exists in the filesystem, extend it by appending a new section (`## Claude Onboarding Agent — Content Creator Setup`) rather than overwriting.

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

## Step 4: Completion Summary

```
✓ Content Creator setup complete!

Files created:
  CLAUDE.md    — brand voice, platform preferences, and audience instructions
  .gitignore   — large media file rules

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Next steps:
  Start a new Claude session and say: "Give me 5 content ideas about [your topic]"
  Or: "Write a YouTube script about [topic] in my brand voice"
  Or: "Turn this blog post into an Instagram caption: [paste content]"
```
