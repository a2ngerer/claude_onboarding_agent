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
- Otherwise: mentally run `skills/_shared/render-anchor-section.md` with `setup_type: detected_setup`, `skill_slug: anchors`, `anchor_slug`, `target_file`, and the embedded fallback snapshot provided at the bottom of this SKILL. **Do not write yet** — compute the proposed excerpt body only. Capture the protocol's `render_freshness` output.
- Locate the existing marker section in the target file using the regex `<!--\s*onboarding-agent:start\s+setup=\S+\s+skill=\S+\s+section=anchor-<anchor_slug>\s*-->`. If no match → skip this (target_file, anchor_slug) pair. `/anchors` only refreshes sections that already exist.
- If the proposed excerpt body differs from the existing section body → append a `{change_id, anchor_slug, file, proposed_body, existing_body, render_freshness}` entry to `proposed_changes`.
- Whenever `render_freshness` is anything other than `network` or `cache`, record the pair `(anchor_slug, render_freshness)` in `anchor_freshness_notes` (deduplicate across target files).

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

Anchor freshness:
  [omit the whole block if anchor_freshness_notes is empty; otherwise one line per unique entry:
   Anchor <anchor_slug> served from <render_freshness> — upstream was unreachable or malformed; re-run /anchors once connectivity returns.]

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
