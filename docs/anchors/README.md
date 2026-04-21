# Realtime Anchors

Anchors are short, auto-updated markdown snapshots of best-practice topics that change faster than plugin releases (current model IDs, recommended tooling, MCP servers, etc.).

Skills fetch anchors **at runtime** from the pinned raw URL on `main` — users never need to update the plugin to get current recommendations.

## Fetch URL

```
https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/docs/anchors/<name>.md
```

This is the **only** host and path allowed. The shared `skills/_shared/fetch-anchor.md` protocol enforces it.

## File layout

Each anchor is a single markdown file in this directory (`docs/anchors/`) named `<name>.md` where `<name>` is a kebab-case slug.

## Required frontmatter

Every anchor begins with YAML frontmatter:

```yaml
---
name: <kebab-case slug; matches the filename>
description: <one-line summary>
last_updated: <YYYY-MM-DD, UTC>
sources:
  - <canonical URL the content is derived from>
  - <another source URL>
version: <integer, bumped on every content change>
---
```

All five fields are required. The daily updater (see `.github/workflows/update-anchors.yml`) relies on `sources` for research and bumps `last_updated` + `version` on change.

## Source architecture

Two layers of input feed the daily updater:

- **Canonical sources** (per anchor, in the frontmatter `sources:` list). These are authoritative documentation URLs that define factual truth for the anchor (e.g. Anthropic docs for `claude-models`, the MCP registry for `mcp-servers`). The updater never adds URLs to this list — a source change is a separate human PR.
- **Trend sources** (global, in `docs/anchors/_trend-sources.md`). Exactly three URLs that act as a trend radar, picking up new patterns (community releases, new workflows) before they land in official docs. Each trend source declares a `covers:` list of anchor slugs it informs. `_trend-sources.md` is **not itself an anchor** — consumers never fetch it.

Per daily run, the updater makes two passes per anchor:

1. Canonical pass — verify facts against the anchor's `sources:` URLs.
2. Trend pass — scan trend sources whose `covers:` list includes this anchor, and propose body updates for newly-surfaced items that fit the anchor's topic.

Every rewrite records `pass`, `source`, and `rationale` in the PR body for reviewer trail.

## Body rules

- **Max 100 lines** in the body (everything after the closing `---`). Skills read anchors into context on every run.
- Structure with `##` section headers. Prefer bullet lists and short tables over prose.
- Machine-parsable > pretty. Keep section names stable — skills may look them up by heading.
- No secrets, no PII, no URLs outside the `sources` list introduced without a human PR.

## How skills consume anchors

Skills call the shared protocol at `skills/_shared/fetch-anchor.md`:

1. Cache lookup at `~/.claude/cache/anchors/<name>.md` (24h TTL)
2. `WebFetch` the pinned URL on miss
3. Fall back to an embedded snapshot the calling skill provides, if both cache and network fail

A skill that needs an anchor must ship an embedded fallback so it still works offline.

## Security

- Fetches are restricted to `raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/docs/anchors/*`. No other host, no redirects.
- Update PRs from the daily workflow are **never auto-merged** — a human reviewer must approve. Anchors are pulled into user projects at runtime, so merge is the trust boundary.
- The cache lives under `~/.claude/cache/anchors/` only. Skills must not write anchor content into user project paths.

## Adding a new anchor

1. Create `docs/anchors/<name>.md` with the required frontmatter and a body ≤ 100 lines.
2. List every source URL in `sources` — the updater only researches URLs that are already listed.
3. If a skill will consume it, add an embedded fallback snapshot in that skill's SKILL.md.
4. Open a PR. Do not include generated cache files.

> `_trend-sources.md` is **not** an anchor. It is a workflow-only file read by the daily updater. Do not place it under the consumer fetch path and do not extend the consumer fetch protocol to it. To change trend sources, open a separate human PR modifying only that file.
