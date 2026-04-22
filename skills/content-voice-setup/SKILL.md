---
name: content-voice-setup
description: Set up Claude for on-brand content voice. Generates per-platform voice rules keyed on your brand voice and target audience. Does NOT cover publishing, analytics, or media pipelines — this skill is scoped to voice only.
---

# Content Voice Setup

This skill configures Claude to write in your brand voice across the platforms you select. It generates a small CLAUDE.md pointer plus one `.claude/rules/content-voice-<platform>.md` file per selected platform. It does NOT configure publishing tools, analytics, media pipelines, or scheduling — that is out of scope and intentionally so.

**Handoff context:** Read `skills/_shared/consume-handoff.md` and run it with the handoff block (if any). The helper guarantees the following locals: `detected_language`, `existing_claude_md`, `inferred_use_case`, `repo_signals`, `graphify_candidate`. Use `detected_language` for all user-facing prose; generated file content stays in English.

**Existing CLAUDE.md:** If `existing_claude_md: true`, DO NOT overwrite it. Append a new delimited section at the end of the file:

```
<!-- onboarding-agent:start setup=content-voice skill=content-voice-setup section=claude-md -->
## Claude Onboarding Agent — Content Voice Setup
...generated content...
<!-- onboarding-agent:end -->
```

If the delimited block already exists from a previous run, replace only the content between the markers; leave the rest untouched. Wrap generated `.gitignore` entries in `# onboarding-agent: content-voice — start` / `— end` markers so `/upgrade-setup` can refresh them non-destructively.

## Supporting Files

Read these on-demand at the step that invokes them. Do not read eagerly.

- `skills/_shared/consume-handoff.md` — orchestrator handoff parse + inline fallback (preamble, before Step 1)

## Step 1: Install Dependencies

Read `skills/_shared/installation-protocol.md` and follow it for each dependency below.

Dependencies:
- Superpowers (optional) — description: "A free Claude Code skills library (94,000+ users). The brainstorming skill is useful for exploring angles before committing to a voice for a given piece." — marketplace-id: `superpowers@claude-plugins-official`, github: `https://github.com/obra/superpowers`, name: `superpowers`

## Step 2: Context Questions

Ask one at a time:

1. "Which platforms do you create voice-driven content for? (multi-select — comma-separated letters, at least one)
   A) YouTube (long-form video / scripts)
   B) Short-form video (Instagram Reels / TikTok / Shorts)
   C) Newsletter / blog (written long-form)
   D) Podcast (conversational audio)"

   Parse the answer into a list of letters. Require at least one selection — re-ask once on empty input. Store as `selected_platforms`. Map to slugs:
   - A → `youtube`
   - B → `shortform`
   - C → `newsletter`
   - D → `podcast`

2. "How would you describe your brand voice? Be as specific as possible — the more detail, the better Claude will match your style.
   Examples: 'educational but casual, like explaining things to a smart friend', 'professional thought leader in fintech', 'funny and irreverent tech commentary', 'warm and personal wellness content'"

   Store the answer verbatim as `brand_voice`. The per-platform rule files inject it into their header.

3. "Who is your target audience? (e.g., 'developers aged 25–40 interested in AI tools', 'small business owners with no tech background', 'fitness enthusiasts looking for quick workouts')"

   Store as `target_audience`.

## Step 3: Emit Per-Platform Voice Rules

For each slug in `selected_platforms`, write a rule file at `.claude/rules/content-voice-<slug>.md`. If the file already exists, skip the write and log `Skipped .claude/rules/content-voice-<slug>.md (already exists)` — do NOT overwrite user edits.

Each rule file is self-contained (≤ 40 lines) and substitutes `brand_voice` and `target_audience` into the header. Use the templates below, replacing `[brand_voice]` and `[target_audience]` with the captured answers.

### content-voice-youtube.md

```markdown
# Content Voice — YouTube (long-form video)

Voice profile: [brand_voice]
Target audience: [target_audience]

## Format rules
- Every script opens with a hook in the first 30 seconds: promise a concrete payoff the viewer will get by the end.
- Structure: hook → setup (what problem / question) → payoff (the answer, story, or demo) → CTA.
- The CTA names one single action. Do not chain "like, subscribe, comment, join" lists.
- Keep sentences readable aloud — default to ≤ 20 words per spoken line.

## Tone rules
- Match the voice profile above in every draft. If a draft would read as generic AI commentary, rewrite the opening line until it sounds like [brand_voice].
- Address the target audience directly. Assume their baseline knowledge; do not explain what they already know.

## Do not
- Do not write title-bait the intro does not deliver on — the hook must be a truthful setup for the payoff.
```

### content-voice-shortform.md

```markdown
# Content Voice — Short-form video (Reels / TikTok / Shorts)

Voice profile: [brand_voice]
Target audience: [target_audience]

## Format rules
- Line 1 IS the hook. Scroll-stop happens in the first two seconds.
- One single idea per post. If a second idea matters, it is a separate post.
- End with a question, a CTA, or a concrete takeaway — never trail off.
- Keep total word count tight (≈ 30–60 spoken words for a 30-second cut).

## Tone rules
- Voice profile matches [brand_voice] exactly — short form amplifies voice, so generic tone is the default failure mode.
- Target [target_audience]; do not soften for a broader audience.

## Do not
- Do not bury the hook past line 1. Do not open with a throat-clearing "So, today I want to talk about …".
```

### content-voice-newsletter.md

```markdown
# Content Voice — Newsletter / blog (written long-form)

Voice profile: [brand_voice]
Target audience: [target_audience]

## Format rules
- Subject line is specific, not clever — name the takeaway or the question the reader gets answered.
- Opener is personal or story-based (1–3 sentences); then one core idea; then a clear takeaway; then a simple CTA.
- Section breaks are allowed but not required — err toward one tight argument over a listicle.
- Close with one sentence the reader could forward to a colleague.

## Tone rules
- Voice profile matches [brand_voice] throughout — no section should sound like a different author wrote it.
- Address [target_audience] by their actual situation, not by role labels.

## Do not
- Do not send an edition without a specific takeaway the reader can act on or remember.
```

### content-voice-podcast.md

```markdown
# Content Voice — Podcast (conversational audio)

Voice profile: [brand_voice]
Target audience: [target_audience]

## Format rules
- Cold-open with a hook — a scene, a question, or a concrete moment from the episode. Intro music comes after.
- Transitions are spoken, not jump-cut: name the shift ("Let's come back to that in a minute — first, …").
- Prep questions in advance, but leave room for follow-ups; a pre-written script reads as a pre-written script.
- End with the guest's CTA (if any), then a single host CTA.

## Tone rules
- Voice profile [brand_voice] applies to host lines; match guests' energy rather than forcing them into it.
- Keep jargon at [target_audience]'s level; translate on first use.

## Do not
- Do not lecture — stay conversational. If a segment reads as a monologue, cut it or reframe as a question.
```

Collect the list of files actually written (minus any that were skipped due to existing files) as `emitted_voice_files` for the completion summary.

## Step 4: Generate Artifacts

### CLAUDE.md

```markdown
# Claude Instructions — Content Voice

## Brand
Platforms: [comma-separated from selected_platforms]
Brand voice: [brand_voice]
Target audience: [target_audience]

## Scope
This setup covers voice only — not publishing, analytics, or media pipelines. For longer content workflows, layer additional skills or tools on top.

## Voice rules (per platform)
[For each slug in selected_platforms, emit one bullet pointing at the rule file:]
- YouTube: `.claude/rules/content-voice-youtube.md`
- Short-form video: `.claude/rules/content-voice-shortform.md`
- Newsletter / blog: `.claude/rules/content-voice-newsletter.md`
- Podcast: `.claude/rules/content-voice-podcast.md`

## Guidelines
- Always write in the brand voice defined above — never sound generic or like a typical AI.
- Before drafting, consult the relevant `.claude/rules/content-voice-<platform>.md` file for the target platform.
- When asked for cross-platform adaptations, apply each platform's rule file individually — do not copy-paste between formats.

[Include ONLY if superpowers_installed is true]
## Superpowers
Superpowers is installed. For ideation sessions and planning content series, use `superpowers:brainstorming` to explore angles before committing to a direction.
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

## Step 5: Write Upgrade Metadata

Set `setup_slug: content-voice`, `skill_slug: content-voice-setup`. Resolve `plugin_version` from the plugin's own `plugin.json`. Then follow `skills/_shared/write-meta.md` to create or merge `./.claude/onboarding-meta.json`.

## Step 6: Render Anchor Sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: content-voice`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: content-voice`
   - `skill_slug: content-voice-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.

For every call, also capture `render_freshness`. When it is anything other than `network` or `cache` (i.e. `fallback` or `embedded`), record the `(anchor_slug, render_freshness)` pair in `anchor_freshness_notes`. The completion summary's `Anchor freshness` line consumes this list.

## Step 7: Completion Summary

```
✓ Content Voice setup complete!

Scope: brand voice + per-platform tone rules. Publishing, analytics, and
media pipelines are NOT covered — this skill is intentionally narrow.

Files created:
  CLAUDE.md                                    — brand, scope, pointers to voice rules
  .claude/rules/content-voice-<slug>.md        — one file per selected platform [list emitted_voice_files; note skipped ones as "(already existed — left untouched)"]
  .gitignore                                   — large media file rules
  .claude/onboarding-meta.json                 — setup marker for /upgrade-setup

External skills:
  [✓ Superpowers installed via superpowers_method (superpowers_scope)]
  [skipped — install later with: /plugin install superpowers@claude-plugins-official]
  [⚠ Superpowers installation failed — install manually: https://github.com/obra/superpowers]

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per entry:
   Anchor <anchor_slug> served from <render_freshness> — consider running /anchors to refresh.]

Next steps:
  Start a new Claude session and say: "Draft a [YouTube script | short-form hook | newsletter edition | podcast cold-open] about [topic] in my brand voice"
  Or: "Adapt this blog post for Instagram Reels, following my short-form voice rules"
  - Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```
