# Anchor Consumer Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the redesigned anchor set into the consumer-facing skills: setup skills render curated excerpts into `CLAUDE.md` marker sections at onboarding time, a new `/anchors` slash command refreshes those sections on demand, `/tipps` Pass 5 generalizes to run per-anchor checks, and `/upgrade` Pass 2 recognizes anchor-derived marker sections as diff targets.

**Architecture:** A shared mapping file declares which anchors apply to each setup type. A shared render protocol is the single implementation of "fetch anchor, extract the curated excerpt, write it into a marker section." Each primary setup skill calls the render protocol once per mapped anchor. The new `/anchors` skill uses the same protocol to refresh existing marker sections. `/tipps` and `/upgrade` are extended along the same pattern without duplicating fetch logic. The security invariant — raw anchor markdown never lands in the user's repo — is preserved: only curated excerpts, produced by the render protocol, are written.

**Tech Stack:** Markdown skills, `WebFetch` via the shared `skills/_shared/fetch-anchor.md` protocol, JSON meta file (`./.claude/onboarding-meta.json`), marker sections (`<!-- onboarding-agent:start ... -->`).

**Spec:** `docs/superpowers/specs/2026-04-21-anchor-redesign-design.md` — read section 4 in full before starting.

**Depends on:** The anchor-redesign branch `feat/anchor-redesign` must be merged first. The five anchors and the reshaped `mcp-servers.md` (with `## Recommended`) must exist on `main`.

---

### Task 1: Create `skills/_shared/anchor-mapping.md`

**Files:**
- Create: `skills/_shared/anchor-mapping.md`

- [ ] **Step 1: Write the mapping file**

```markdown
# Setup → Anchor Mapping

This file is the single source of truth for which anchors each setup type renders. Read by: setup skills (at generation time), `/anchors` (at refresh time), `/tipps` Pass 5, `/upgrade` Pass 2.

## Mapping

| Setup type | Anchors |
|---|---|
| `coding` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |
| `data-science` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |
| `devops` | `claude-models`, `mcp-servers`, `claude-tools` |
| `design` | `claude-models`, `mcp-servers`, `claude-tools` |
| `content-creator` | `claude-models`, `claude-tools` |
| `office` | `claude-models`, `claude-tools` |
| `research` | `claude-models`, `claude-tools` |
| `academic-writing` | `claude-models`, `claude-tools` |
| `knowledge-base` | `claude-models`, `claude-tools`, `subagents`, `knowledge-base` |
| `web-development` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |

## Delegated skills

`graphify-setup` is delegated — it inherits its host setup's `setup_type` in the meta file and does not render its own anchor marker sections. If `graphify-setup` runs standalone, no anchor sections are rendered for it.

## How callers use this file

1. Look up the user's `setup_type` (from `./.claude/onboarding-meta.json` or by asking).
2. Find the corresponding row in the mapping table.
3. For each anchor slug in that row, call `skills/_shared/render-anchor-section.md` (setup skills, `/anchors`) or read the anchor for section-based checks (`/tipps`, `/upgrade`).

Unknown `setup_type` values: callers must treat this as "no anchors" (degrade gracefully, do not fail).
```

- [ ] **Step 2: Commit**

```bash
git add skills/_shared/anchor-mapping.md
git commit -m "feat(shared): add setup→anchor mapping (single source of truth for all anchor consumers)"
```

---

### Task 2: Create `skills/_shared/render-anchor-section.md`

**Files:**
- Create: `skills/_shared/render-anchor-section.md`

- [ ] **Step 1: Write the protocol**

```markdown
# Render-Anchor-Section Protocol

Shared protocol for rendering a curated excerpt of an anchor into a delimited marker section of a user's config file (typically `CLAUDE.md` or `AGENTS.md`). Called by primary setup skills during onboarding and by `/anchors` during refresh.

## Inputs

- `setup_type` — the user's setup slug (e.g. `coding`, `knowledge-base`).
- `skill_slug` — the calling skill's directory name (e.g. `coding-setup`, `anchors`).
- `anchor_slug` — the anchor to render (e.g. `claude-models`).
- `target_file` — absolute or project-relative path (e.g. `./CLAUDE.md`).
- `fallback_content` — an embedded anchor snapshot provided by the caller, passed through to `fetch-anchor.md`.

## Outputs

- `render_result` — one of `rendered`, `placeholder`, `unchanged`, `skipped`.

## Security invariants

- The full raw anchor markdown is NEVER written to the target file. Only the curated excerpt defined in Step R3 below.
- No URLs or code blocks from the anchor body are written without the excerpt-extraction step running first.
- `fetch-anchor.md` security invariants apply unchanged (only the pinned `raw.githubusercontent.com` URL, cache under `~/.claude/cache/anchors/`).

## Protocol Steps

### Step R1 — Fetch the anchor

Call `skills/_shared/fetch-anchor.md` with `anchor_name: <anchor_slug>` and `fallback_content: <fallback_content>`.

- If `anchor_markdown` is non-null → continue to Step R2.
- If `anchor_markdown` is null → set `render_result: placeholder` and skip to Step R4 with the excerpt body:
  ```
  <!-- anchor unavailable at render time — run /anchors to retry -->
  ```

### Step R2 — Parse the anchor body

Split `anchor_markdown` on the first two `---` fences into frontmatter + body. Parse the body into `## <Heading>` sections keyed by heading text.

### Step R3 — Extract the curated excerpt per anchor

Select the excerpt section by anchor slug (exact match required, falling back to a conservative default if the section is missing):

| `anchor_slug` | Primary section to extract | Fallback if missing |
|---|---|---|
| `claude-models` | `## Defaults` | first 20 lines of body |
| `mcp-servers` | `## Recommended` | `## Selection tips` |
| `claude-tools` | `## Recommendations` | `## Memory files` |
| `subagents` | `## Recommendations` | `## When to use a subagent` |
| `knowledge-base` | `## Recommended layout` | `## Vault layout` |

The excerpt is the content between the chosen `## <Heading>` line (exclusive) and the next `## ` line (or end of body). Strip trailing blank lines. If the extracted text exceeds 25 lines, truncate to 25 lines and append `<!-- excerpt truncated — see full anchor in cache -->` as the last line.

### Step R4 — Write the marker section

Construct the section block exactly (replace the three placeholders):

```
<!-- onboarding-agent:start setup=<setup_type> skill=<skill_slug> section=anchor-<anchor_slug> -->
<excerpt body>
<!-- onboarding-agent:end -->
```

Open `<target_file>`:

- If the file does not exist → create it with just the block. Set `render_result: rendered`.
- If the file exists and a section with the same three-attribute signature (`setup=...`, `skill=...`, `section=anchor-<anchor_slug>`) already exists → replace only the body between its start and end markers with the new excerpt body. The start and end marker lines themselves stay. If the resulting body is byte-identical to the prior body → set `render_result: unchanged` and do not rewrite the file. Otherwise set `render_result: rendered`.
- If the file exists but does not contain a matching marker section → append two blank lines then the block at the end of the file. Set `render_result: rendered`.

Never touch bytes outside the marker pair.

### Step R5 — Return

Return `render_result`.

## Notes for callers

- Setup skills call this protocol once per anchor in their mapped list. Each call is independent — if one anchor fetch fails, the others still run.
- `/anchors` uses this protocol only on files that already exist; it does not create `CLAUDE.md` or `AGENTS.md` from scratch. Section 4.3 of the spec is explicit that initial creation is the setup skill's job.
- `fallback_content` must be a plausible-shape markdown anchor (frontmatter + body) so Step R2 can parse it. If omitted, Step R1 may return null, leading to the placeholder path in Step R4.
```

- [ ] **Step 2: Commit**

```bash
git add skills/_shared/render-anchor-section.md
git commit -m "feat(shared): add render-anchor-section protocol (DRY primitive for all anchor consumers)"
```

---

### Task 3: Create `skills/anchors/SKILL.md`

**Files:**
- Create: `skills/anchors/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: anchors
description: Refresh the anchor-derived marker sections in this project's CLAUDE.md and AGENTS.md by re-fetching the latest anchors, diffing against on-disk content, and applying confirmed changes. Supports --dry-run.
---

# Anchors — Refresh Anchor-Derived Sections

Refresh the marker sections of CLAUDE.md / AGENTS.md that were originally rendered by a setup skill from anchor content. This skill is the narrow counterpart to `/upgrade`: `/upgrade` refreshes all plugin-owned sections (templates + anchors); `/anchors` refreshes only anchor-derived sections.

## Language

Detect language from the user's first message in this invocation and respond in it throughout. All file content written to disk stays in English (repo language rule).

## Argument parsing

The invocation may contain `--dry-run` anywhere in the argument string.

- If present: set `dry_run: true`. Print diffs but write nothing.
- Otherwise: set `dry_run: false`.

Any other argument is ignored silently.

## Pass 1 — Detect the setup

### Step 1.1 — Read meta file

Read `./.claude/onboarding-meta.json` if it exists. Expected shape per `skills/_shared/write-meta.md`.

- If the file parses and `setup_type` is a recognized slug (one of: `coding`, `data-science`, `design`, `knowledge-base`, `devops`, `content-creator`, `office`, `research`, `academic-writing`, `web-development`) → set `detected_setup: <setup_type>`, `meta_source: meta-file`.
- If the file parses and `setup_type` is `graphify` → print "`/anchors` has no work to do for a standalone graphify setup — anchor sections only apply to primary setups." and exit cleanly.
- If the file is missing or malformed → ask the user: "No setup detected. Which setup type does this project use? (coding, data-science, design, devops, web-development, knowledge-base, content-creator, office, research, academic-writing)". Accept any of those ten as `detected_setup`. Any other reply → exit without changes.

### Step 1.2 — Load anchors for this setup

Read `skills/_shared/anchor-mapping.md`. Parse the mapping table. Extract the anchor list for `detected_setup` → `anchors_for_setup`.

If the list is empty (unmapped setup type): print "No anchors mapped for setup `<detected_setup>` — nothing to refresh." and exit cleanly.

## Pass 2 — Compute diffs

For each `anchor_slug` in `anchors_for_setup`:

### Step 2.1 — Fetch and render

For each target file in `["./CLAUDE.md", "./AGENTS.md"]`:

- If the target file does not exist → skip (this skill does not create files).
- Otherwise: mentally run `skills/_shared/render-anchor-section.md` with `setup_type: detected_setup`, `skill_slug: anchors`, `anchor_slug`, `target_file`, and the embedded fallback snapshot provided at the bottom of this SKILL. **Do not write yet** — compute the proposed excerpt body only.
- Locate the existing marker section in the target file using the regex `<!--\s*onboarding-agent:start\s+setup=\S+\s+skill=\S+\s+section=anchor-<anchor_slug>\s*-->`. If no match → skip this (target_file, anchor_slug) pair. `/anchors` only refreshes sections that already exist.
- If the proposed excerpt body differs from the existing section body → append a `{change_id, anchor_slug, file, proposed_body, existing_body}` entry to `proposed_changes`.

### Step 2.2 — Early exit when nothing to do

If `proposed_changes` is empty:

```
Nothing to refresh — your anchor sections are already up to date.
```

Update `./.claude/onboarding-meta.json` with `anchors_refreshed_at: <ISO-8601 UTC timestamp>` (unless `dry_run`) and exit.

## Pass 3 — Confirm each change

Print:

```
Found <N> anchor section(s) to refresh. Answer y / n / all / skip-rest for each.
```

For each entry (stable order: by file path, then by `anchor_slug`):

```
[<change_id>] <file> · anchor-<anchor_slug>

<unified diff of existing_body → proposed_body, 3 lines of context>

apply? (y/n/all/skip-rest)
```

Interpret replies: `y/yes` → accept; `n/no` → reject; `all` → accept this and all remaining; `skip-rest` → reject this and all remaining. Any other reply → re-prompt once, default to `n`.

After the loop:

```
Accepted: <A> · Skipped: <S> · Total: <N>
```

If `A == 0` → go to Pass 5 without writing.

## Pass 4 — Backup and apply

If `dry_run: true` → print `Dry-run mode — no files written.` and go to Pass 5.

### Step 4.1 — Backup

`timestamp = <YYYYMMDD-HHMMSS>` in local time. For each unique file in accepted changes, `mkdir -p ./.claude/backups/<timestamp>/` and copy the current on-disk file preserving relative path.

### Step 4.2 — Apply

For each accepted change, rewrite only the body between the existing marker pair to the `proposed_body`. Never touch bytes outside the markers. If any single file write throws → stop immediately, print:

```
⚠ Write failed for <file>: <error>. Refresh halted.
   Backup of the pre-refresh state is at .claude/backups/<timestamp>/
```

Do not attempt on-the-fly rollback. The backup is the recovery path.

### Step 4.3 — Meta update

Read `./.claude/onboarding-meta.json`. Set `anchors_refreshed_at: <ISO-8601 UTC timestamp>`. Leave all other keys unchanged. Write back with 2-space indent.

## Pass 5 — Summary

```
✓ Anchors <refreshed | dry-run complete>

Summary:
  Applied:      <A>
  Skipped:      <S>
  Dry-run only: <D>

Backup folder: <./.claude/backups/<timestamp>/ | n/a — nothing applied>

Next:
  - Run /tipps to audit the updated setup.
  - /anchors is idempotent — safe to re-run any time.
```

## Embedded fallbacks

These fallback snapshots are passed to `render-anchor-section.md` when the network and cache are both unavailable. Each is a minimal shape that parses through Step R2 and Step R3 of the render protocol. They are intentionally short — fallbacks are last-resort.

### Fallback for `claude-models`

```markdown
---
name: claude-models
description: Minimal embedded fallback
last_updated: 2026-04-21
sources: []
version: 1
---

## Defaults

- Coding default: `claude-sonnet-4-6`
- Deep reasoning: `claude-opus-4-7`
- High-throughput subagents: `claude-haiku-4-5-20251001`
```

### Fallback for `mcp-servers`

```markdown
---
name: mcp-servers
description: Minimal embedded fallback
last_updated: 2026-04-21
sources: []
version: 1
---

## Recommended

- `filesystem` — scoped filesystem access
- `git` — git history and diffs
- `github` — issues and PRs
```

### Fallback for `claude-tools`

```markdown
---
name: claude-tools
description: Minimal embedded fallback
last_updated: 2026-04-21
sources: []
version: 1
---

## Recommendations

- Keep CLAUDE.md short — point to separate files for detail.
- Use `.claude/settings.json` `permissions.allow` rather than blanket wildcards.
- Hooks handle automation; memory files handle preferences.
```

### Fallback for `subagents`

```markdown
---
name: subagents
description: Minimal embedded fallback
last_updated: 2026-04-21
sources: []
version: 1
---

## Recommendations

- Delegate broad exploration (3+ queries) to an Explore subagent.
- Dispatch independent tasks in parallel in a single message.
- Keep subagent prompts self-contained — they have no conversation context.
```

### Fallback for `knowledge-base`

```markdown
---
name: knowledge-base
description: Minimal embedded fallback
last_updated: 2026-04-21
sources: []
version: 1
---

## Recommended layout

- PARA-inspired with numeric prefixes: `00_inbox/`, `10_areas/`, `20_resources/`, `30_archive/`.
- Keep daily notes separate from topical notes.
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/anchors/SKILL.md
git commit -m "feat(skills): add /anchors skill for refreshing anchor-derived marker sections"
```

---

### Task 4: Register `/anchors` in `.claude-plugin/plugin.json`

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Read the current manifest**

```bash
cat .claude-plugin/plugin.json
```

Identify the `skills` array and the `commands` array.

- [ ] **Step 2: Add the new skill entry**

Append `"skills/anchors"` to the `skills` array. Keep existing order.

- [ ] **Step 3: Add the new command entry**

Append a command entry to the `commands` array. Mirror the shape of the existing `/tipps` or `/upgrade` entry. Typical shape:

```json
{
  "name": "anchors",
  "description": "Refresh anchor-derived marker sections in CLAUDE.md/AGENTS.md",
  "skill": "anchors"
}
```

- [ ] **Step 4: Validate JSON**

```bash
uv run --with '' python -c "import json; json.load(open('.claude-plugin/plugin.json'))"
```

Expected: exit status 0, no output.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat(plugin): register /anchors skill and slash command"
```

---

### Task 5: Add the render step to `coding-setup`

**Files:**
- Modify: `skills/coding-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

Read `skills/coding-setup/SKILL.md`. Find the last substantive step before the completion-summary / final user-facing output. The render step must happen after all file generation but before the user sees the summary.

- [ ] **Step 2: Insert the render step**

Insert a new step with this exact content. Use the next sequential step number in the existing numbering scheme.

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: coding`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: coding`
   - `skill_slug: coding-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder` — that is the designed offline path. Collect the list of rendered / placeholder slugs to mention in the completion summary.
```

- [ ] **Step 3: Update the completion summary**

In the skill's completion-summary step, add one line after the existing "Next steps" content:

```
- Run `/anchors` any time to refresh the anchor-derived sections. If any section was rendered as a placeholder due to offline mode, re-run `/anchors` once you are back online.
```

- [ ] **Step 4: Commit**

```bash
git add skills/coding-setup/SKILL.md
git commit -m "feat(coding-setup): render anchor sections on generation"
```

---

### Task 6: Add the render step to `data-science-setup`

**Files:**
- Modify: `skills/data-science-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5, Step 1, but for this skill.

- [ ] **Step 2: Insert the render step**

Same pattern as Task 5 Step 2, but with these substitutions:
- `setup_type: data-science`
- `skill_slug: data-science-setup`

Full block to insert:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: data-science`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: data-science`
   - `skill_slug: data-science-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs to mention in the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/data-science-setup/SKILL.md
git commit -m "feat(data-science-setup): render anchor sections on generation"
```

---

### Task 7: Add the render step to `devops-setup`

**Files:**
- Modify: `skills/devops-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5, Step 1, for this skill.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: devops`, `skill_slug: devops-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: devops`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: devops`
   - `skill_slug: devops-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/devops-setup/SKILL.md
git commit -m "feat(devops-setup): render anchor sections on generation"
```

---

### Task 8: Add the render step to `design-setup`

**Files:**
- Modify: `skills/design-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: design`, `skill_slug: design-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: design`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: design`
   - `skill_slug: design-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/design-setup/SKILL.md
git commit -m "feat(design-setup): render anchor sections on generation"
```

---

### Task 9: Add the render step to `web-development-setup`

**Files:**
- Modify: `skills/web-development-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: web-development`, `skill_slug: web-development-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: web-development`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: web-development`
   - `skill_slug: web-development-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/web-development-setup/SKILL.md
git commit -m "feat(web-development-setup): render anchor sections on generation"
```

---

### Task 10: Add the render step to `knowledge-base-builder`

**Files:**
- Modify: `skills/knowledge-base-builder/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: knowledge-base`, `skill_slug: knowledge-base-builder`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: knowledge-base`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: knowledge-base`
   - `skill_slug: knowledge-base-builder`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/knowledge-base-builder/SKILL.md
git commit -m "feat(knowledge-base-builder): render anchor sections on generation"
```

---

### Task 11: Add the render step to `academic-writing-setup`

**Files:**
- Modify: `skills/academic-writing-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: academic-writing`, `skill_slug: academic-writing-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: academic-writing`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: academic-writing`
   - `skill_slug: academic-writing-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/academic-writing-setup/SKILL.md
git commit -m "feat(academic-writing-setup): render anchor sections on generation"
```

---

### Task 12: Add the render step to `content-creator-setup`

**Files:**
- Modify: `skills/content-creator-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: content-creator`, `skill_slug: content-creator-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: content-creator`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: content-creator`
   - `skill_slug: content-creator-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/content-creator-setup/SKILL.md
git commit -m "feat(content-creator-setup): render anchor sections on generation"
```

---

### Task 13: Add the render step to `office-setup`

**Files:**
- Modify: `skills/office-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: office`, `skill_slug: office-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: office`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: office`
   - `skill_slug: office-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/office-setup/SKILL.md
git commit -m "feat(office-setup): render anchor sections on generation"
```

---

### Task 14: Add the render step to `research-setup`

**Files:**
- Modify: `skills/research-setup/SKILL.md`

- [ ] **Step 1: Locate the insertion point**

As in Task 5 Step 1.

- [ ] **Step 2: Insert the render step**

Full block with `setup_type: research`, `skill_slug: research-setup`:

```markdown
### Step X — Render anchor sections

Read `skills/_shared/anchor-mapping.md`. Locate the row for `setup_type: research`. For each anchor slug in that row:

1. Call `skills/_shared/render-anchor-section.md` with:
   - `setup_type: research`
   - `skill_slug: research-setup`
   - `anchor_slug: <slug>`
   - `target_file: ./CLAUDE.md`
   - `fallback_content: <embedded fallback from skills/anchors/SKILL.md for that slug>`
2. If a `./AGENTS.md` file was generated earlier in this skill, repeat the call with `target_file: ./AGENTS.md`.

Do not fail if any single `render-anchor-section.md` call returns `placeholder`. Collect rendered / placeholder slugs for the completion summary.
```

- [ ] **Step 3: Update the completion summary**

Same line as Task 5 Step 3.

- [ ] **Step 4: Commit**

```bash
git add skills/research-setup/SKILL.md
git commit -m "feat(research-setup): render anchor sections on generation"
```

---

### Task 15: Update the onboarding skill to mention `/anchors`

**Files:**
- Modify: `skills/onboarding/SKILL.md`

- [ ] **Step 1: Locate the final hand-off step**

The onboarding skill delegates to a primary setup skill and then prints a final summary to the user. Locate that final summary step.

- [ ] **Step 2: Append the `/anchors` hint**

Add this line to the final summary output:

```
- Run `/anchors` any time after setup to refresh the anchor-derived best-practice sections. Setup already rendered an initial version; `/anchors` refreshes them against the latest upstream anchors.
```

- [ ] **Step 3: Commit**

```bash
git add skills/onboarding/SKILL.md
git commit -m "feat(onboarding): mention /anchors in the final summary"
```

---

### Task 16: Generalize `/tipps` Pass 5

**Files:**
- Modify: `skills/tipps/SKILL.md`

- [ ] **Step 1: Read the current Pass 5**

Read `skills/tipps/SKILL.md`, locate `## Pass 5 — Realtime Anchors`. Today it runs one check against the `claude-models` anchor.

- [ ] **Step 2: Replace Pass 5 with the generalized version**

Replace the entire `## Pass 5 — Realtime Anchors` section (up to the next `---` divider) with this content:

```markdown
## Pass 5 — Realtime Anchors

Read `./.claude/onboarding-meta.json` if present → `setup_type`. If the file is absent or malformed, skip this pass entirely (today's behavior for untracked projects is preserved by falling through).

Read `skills/_shared/anchor-mapping.md` → extract the list of anchor slugs mapped to `setup_type` → `anchors_for_setup`. If the mapping yields no anchors (unknown setup_type), skip this pass.

For each `anchor_slug` in `anchors_for_setup`, fetch the anchor via `skills/_shared/fetch-anchor.md` (embedded fallback: use the snapshot declared in `skills/anchors/SKILL.md` for that slug). If `fetch-anchor` returns `anchor_markdown: null`, skip that slug and continue.

Run the anchor-specific check defined below. Each check is `LOW` severity and produces at most one finding per anchor.

### Check 5.1 — `claude-models` deprecated-ID reference `[MEDIUM]`

(Unchanged from prior behavior.) From the fetched `claude-models` anchor, parse the `## Deprecated` section into a list of deprecated model IDs. If any of the already-scanned files (`CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`) contains a string exactly matching one of those IDs, emit a MEDIUM finding: "Deprecated Claude model ID referenced in config. Replace with the current equivalent from the anchor's `## Model IDs` table."

### Check 5.2 — `mcp-servers` not in recommended list `[LOW]`

Only runs if `.claude/settings.json` exists and has a non-empty `mcpServers` object. From the fetched `mcp-servers` anchor, parse the `## Recommended` section into a set of server names (each bullet's backticked identifier). For each key in `settings.json`'s `mcpServers` not present in that set, emit one LOW finding: "MCP server `<name>` is not on the current recommended list — review whether it still fits your setup."

### Check 5.3 — `claude-tools` deprecated pattern present `[LOW]`

From the fetched `claude-tools` anchor, parse the `## Deprecated patterns` section into a list of pattern descriptors. Each bullet is expected to mention an exact file, key, or directory name in backticks. For each backticked name that the scan finds present in the repo (via `.claude/settings.json` keys or files under `.claude/`), emit one LOW finding: "`<pattern>` is marked deprecated in the current claude-tools anchor — migrate to the recommended alternative."

### Check 5.4 — `subagents` anti-pattern reference `[LOW]`

Only runs if the project has any subagent definition files under `.claude/agents/`. From the fetched `subagents` anchor, parse the `## Anti-patterns` section. For each anti-pattern, check whether any subagent definition file or `.claude/settings.json` reference matches the pattern (keyed on backticked names in the anti-pattern bullets). If matched, emit one LOW finding: "Subagent usage pattern `<name>` is flagged as an anti-pattern by the current subagents anchor."

### Check 5.5 — `knowledge-base` layout deviation `[LOW]`

Only runs if `setup_type == knowledge-base`. From the fetched `knowledge-base` anchor, parse the `## Recommended layout` section for the canonical folder names. Scan the top-level directory for folders. If the set of top-level folders in the project differs from the recommended layout (missing recommended folders, or non-recommended folders present), emit one LOW finding: "Vault layout does not match the current knowledge-base anchor recommendation."

If the anchor lacks the required section at fetch time, the corresponding check is silently skipped.

### Pass 5 Fallbacks

The embedded fallback snapshots live in `skills/anchors/SKILL.md`. Read them from there rather than duplicating. (If running this skill standalone without the `/anchors` skill installed, the fetch-anchor network path is the only route — a check will silently skip on offline use.)
```

- [ ] **Step 3: Commit**

```bash
git add skills/tipps/SKILL.md
git commit -m "feat(tipps): generalize Pass 5 to run per-anchor checks for all mapped anchors"
```

---

### Task 17: Extend `/upgrade` Pass 2 to recognize anchor sections

**Files:**
- Modify: `skills/upgrade/SKILL.md`

- [ ] **Step 1: Read the current Pass 2**

Read `skills/upgrade/SKILL.md`, locate `## Pass 2 — Plan the changes`. Step 2.2 enumerates marker sections.

- [ ] **Step 2: Extend Step 2.2**

At the end of Step 2.2 (just before Step 2.3), insert this block:

```markdown
#### Anchor-derived sections

Marker sections whose `section=` attribute starts with `anchor-` are **anchor-derived**, not plugin-template-derived. For these, compute the diff differently:

1. Extract the `anchor_slug` from the `section=anchor-<slug>` attribute.
2. Fetch the anchor via `skills/_shared/fetch-anchor.md` (use the fallback snapshot from `skills/anchors/SKILL.md` for that slug).
3. Mentally run `skills/_shared/render-anchor-section.md` Step R3 to extract the curated excerpt for that slug (same section-selection logic as the render protocol).
4. Compute the unified diff between the on-disk marker body and the proposed excerpt body (3 lines of context).

The `proposed_changes` entry gets `rationale: "Anchor `<slug>` refresh — latest excerpt differs from on-disk body"`. The change behaves identically to template-derived changes in Pass 3 (same y/n/all/skip-rest prompt) and in Pass 4 (same write mechanism — only the body between markers changes).

This means `/upgrade` now implicitly covers what `/anchors` does. `/anchors` remains the focused tool for users who only want to refresh the anchor parts.
```

- [ ] **Step 3: Update Step 2.3 wording**

Step 2.3 (anchor-driven checks for deprecated model IDs) becomes redundant with Check 5.1 of the updated `/tipps` and with the new anchor-derived section handling in Step 2.2. Replace Step 2.3 with a one-line reference:

```markdown
### Step 2.3 — (Removed)

Anchor-driven checks (deprecated model IDs and similar) now live in `/tipps` Pass 5. Anchor section refreshes are handled by the anchor-derived branch of Step 2.2. Nothing to do here.
```

- [ ] **Step 4: Commit**

```bash
git add skills/upgrade/SKILL.md
git commit -m "feat(upgrade): recognize anchor-derived marker sections as diff targets in Pass 2"
```

---

### Task 18: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add `/anchors` to the What's Inside table**

Locate the "What's Inside" table. Add a new row for the `/anchors` command. Match the existing row shape; description: "Refresh anchor-derived marker sections in CLAUDE.md/AGENTS.md against the latest upstream anchors."

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs(readme): list /anchors in What's Inside"
```

---

### Task 19: End-to-end validation on a scratch project

**Files:**
- None modified in this repo. A scratch dir is used outside the repo.

- [ ] **Step 1: Create a scratch project**

```bash
SCRATCH="$(mktemp -d)"
cd "$SCRATCH"
git init
echo "# Scratch" > README.md
git add . && git commit -m "init"
```

- [ ] **Step 2: Simulate onboarding manually**

Write a minimal `./.claude/onboarding-meta.json`:

```bash
mkdir -p .claude
cat > .claude/onboarding-meta.json <<'JSON'
{
  "setup_type": "coding",
  "skills_used": ["coding-setup"],
  "plugin_version": "1.0.0",
  "installed_at": "2026-04-21T12:00:00Z",
  "upgraded_at": null
}
JSON
```

Write a `CLAUDE.md` containing pre-rendered anchor marker sections (simulating what a real `coding-setup` run would have produced):

```bash
cat > CLAUDE.md <<'MD'
# Project

<!-- onboarding-agent:start setup=coding skill=coding-setup section=anchor-claude-models -->
old placeholder body
<!-- onboarding-agent:end -->

<!-- onboarding-agent:start setup=coding skill=coding-setup section=anchor-mcp-servers -->
old placeholder body
<!-- onboarding-agent:end -->

<!-- onboarding-agent:start setup=coding skill=coding-setup section=anchor-claude-tools -->
old placeholder body
<!-- onboarding-agent:end -->

<!-- onboarding-agent:start setup=coding skill=coding-setup section=anchor-subagents -->
old placeholder body
<!-- onboarding-agent:end -->
MD
git add . && git commit -m "seed CLAUDE.md with stale anchor sections"
```

- [ ] **Step 3: Run `/anchors --dry-run`**

Open Claude Code in `$SCRATCH` and invoke `/anchors --dry-run`. Expected flow:

- Skill reads the meta file and confirms `setup_type: coding`.
- Skill fetches all four anchors (`claude-models`, `mcp-servers`, `claude-tools`, `subagents`).
- Skill shows a diff for each of the four marker sections (all have stale placeholder bodies).
- Skill prints "Dry-run mode — no files written."

Verify `CLAUDE.md` is byte-identical to the pre-run state:

```bash
git diff --quiet -- CLAUDE.md && echo "clean" || echo "unexpectedly modified"
```

Expected: `clean`.

- [ ] **Step 4: Run `/anchors` (no flag), accept all**

Invoke `/anchors` (no flag). At each prompt, reply `all`.

Verify changes were applied:

```bash
git diff --name-only
```

Expected: `CLAUDE.md` and `.claude/onboarding-meta.json` appear. The latter now contains `anchors_refreshed_at`.

Verify backup was created:

```bash
ls .claude/backups/
```

Expected: exactly one subdirectory named with a timestamp.

- [ ] **Step 5: Run `/anchors` again, expect no-op**

Invoke `/anchors` a second time. Expected output: "Nothing to refresh — your anchor sections are already up to date."

- [ ] **Step 6: Tear down**

```bash
cd -
rm -rf "$SCRATCH"
```

---

### Task 20: Open the PR

**Files:**
- git state only.

- [ ] **Step 1: Push the feature branch**

```bash
git checkout -b feat/anchor-consumer-integration
git push -u origin feat/anchor-consumer-integration
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create --title "feat(anchors): wire anchors into onboarding, /anchors, /tipps, /upgrade" --body "$(cat <<'EOF'
## Summary

Implements the consumer-side anchor integration from `docs/superpowers/specs/2026-04-21-anchor-redesign-design.md` (section 4):

- New shared `skills/_shared/anchor-mapping.md` (setup → anchor list, single source of truth).
- New shared `skills/_shared/render-anchor-section.md` (DRY render protocol).
- New `/anchors` skill for refreshing anchor-derived marker sections.
- Ten primary setup skills render anchor sections at onboarding time.
- Onboarding skill mentions `/anchors` in the final summary.
- `/tipps` Pass 5 generalized to run per-anchor checks (MEDIUM for deprecated model IDs, LOW for each other anchor check).
- `/upgrade` Pass 2 recognizes `section=anchor-*` markers as anchor-derived diff targets.
- README "What's Inside" lists `/anchors`.

**Depends on:** `feat/anchor-redesign` merged (provides the five anchor files with their `/tipps`-keyed sections).

## Security

- Raw anchor markdown is never written to the user's repo. Only curated excerpts produced by the render protocol land in marker sections.
- Consumer fetches remain restricted to the pinned `raw.githubusercontent.com` URL.
- Cache stays under `~/.claude/cache/anchors/`.

## Test plan

- [x] Task 19 scratch-project validation: `/anchors --dry-run`, `/anchors all`, idempotent re-run.
- [ ] Reviewer: spot-check one setup skill (e.g. `coding-setup`) to confirm the render step is correctly placed.
- [ ] Reviewer: run `/tipps` on an existing project and confirm Pass 5 output includes per-anchor findings, not just the model-ID check.
- [ ] Reviewer: run `/upgrade --dry-run` on a project with stale anchor sections and confirm each section appears as a separate diff.
EOF
)"
```

---

## Self-review checklist

Before handing off:

- [ ] `skills/_shared/anchor-mapping.md` lists exactly the ten primary setups from the spec (nine pre-existing + `web-development`).
- [ ] The render protocol's Step R3 section-selection table matches the `/tipps` check definitions (spec section 4.4).
- [ ] Every primary setup skill has its own task (Tasks 5–14), each with a concrete insertion block using that skill's exact `setup_type` and `skill_slug`.
- [ ] No task references `graphify-setup` for anchor rendering.
- [ ] `/anchors` never creates new marker sections — only refreshes existing ones (spec section 4.3).
- [ ] The scratch-project validation in Task 19 exercises the three main user-visible flows: dry-run, apply, idempotent re-run.
