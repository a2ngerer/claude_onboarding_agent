# Emit End-User Subagent

Shared procedure consumed by setup skills that offer to generate a project-local subagent under `.claude/agents/<slug>.md`. Read before the skill's artifact-generation step.

## Inputs (required)

The calling skill passes these values when invoking the procedure:

- `slug` — kebab-case filename stem, e.g. `<agent-slug>`
- `purpose_blurb` — one-sentence natural-language description of what the subagent does ("Review a PR-sized diff against project conventions.")
- `frontmatter_description` — the exact string to place in the subagent's `description:` field
- `tools_list` — comma-separated string, e.g. `Bash, Read, Grep, Glob`
- `body_markdown` — the subagent's prompt body (everything after the frontmatter)
- `rules_files` — zero or more `.claude/rules/*.md` filenames the subagent should read on dispatch (may be empty)

## Step 1 — Opt-in prompt

Ask the user exactly once (adapt to detected language; keep the slug and file path in English):

```
This skill can generate a project-local subagent (`<slug>`) that Claude
auto-dispatches when the conversation matches its description. The
subagent lives in .claude/agents/<slug>.md and only loads when invoked —
no always-on context cost.

Purpose: <purpose_blurb>

Install <slug> now? (yes / no / later)
```

- **yes** → set `emit_subagent: true`, continue to Step 2.
- **no** → set `emit_subagent: false`, skip to Step 6 (completion-summary hint only).
- **later** → treat as `no` for v1. Set `emit_subagent: false`, `subagent_deferred: true`. Skip to Step 6.

## Step 2 — Collision check

Before writing, check if `.claude/agents/<slug>.md` already exists:

```
test -f .claude/agents/<slug>.md && echo EXISTS || echo MISSING
```

- If `EXISTS`: log `Skipped .claude/agents/<slug>.md (already exists)`, set `subagent_skipped_existing: true`, and skip to Step 5 (metadata update still runs — the file is on disk and should be recorded).
- If `MISSING`: continue to Step 3.

## Step 3 — Ensure target directory and assemble content

1. Run `mkdir -p .claude/agents`.
2. Assemble the file content from this template:

```markdown
---
name: <slug>
description: <frontmatter_description>
tools: <tools_list>
---

<body_markdown>

## Before your first action
1. Read `CLAUDE.md` (project root) for project context.
2. Read the rules files relevant to your scope: <rules_files> (or: none).
3. If a listed rules file is missing, say so in your response header and proceed with best-effort defaults — do not stop.
```

Substitute every angle-bracket placeholder with the value passed by the calling skill. If `rules_files` is empty, write the literal string `none` on line 2 of that section.

## Step 4 — Write

Write the assembled content to `.claude/agents/<slug>.md` using the Write tool.

## Step 5 — Metadata update

Append `<slug>` to the `subagents_installed[]` array in `./.claude/onboarding-meta.json` via `skills/_shared/write-meta.md` (which merges as a union across runs). If the meta file does not yet exist, the calling skill's normal write-meta invocation creates it with `subagents_installed: ["<slug>"]`.

## Step 6 — Completion-summary hint

Regardless of the branch taken, the calling skill's completion summary includes one of these lines:

- `yes` path: `.claude/agents/<slug>.md                 — project-local subagent (auto-invoked)`
- `yes` path, collision skipped: `.claude/agents/<slug>.md (already existed — skipped; re-run /checkup --rebuild to regenerate)`
- `no` / `later` path: `Subagent <slug> not installed — re-run the skill to add it later.`

## Rules for the calling skill

- Call this procedure **after** context questions and the Obsidian-style system-check step (if any), **before** generating CLAUDE.md and other artifacts. Subagent installation is a lightweight file write and does not depend on the rest of the artifact generation.
- Do **not** embed the opt-in prompt text inline in the SKILL.md — read this helper and follow it. Keeps prompts consistent across skills.
- Do **not** vary the collision policy. Skip-on-exists is the contract; regeneration is `checkup --rebuild` territory.
