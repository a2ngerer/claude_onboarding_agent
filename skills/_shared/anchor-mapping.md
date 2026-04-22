# Setup → Anchor Mapping

This file is the single source of truth for which anchors each setup type renders. Read by: setup skills (at generation time), `/anchors` (at refresh time), `/tipps` Pass 5, `/upgrade` Pass 2.

## Mapping

| Setup type | Anchors |
|---|---|
| `coding` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |
| `data-science` | `claude-models`, `mcp-servers`, `claude-tools`, `subagents` |
| `devops` | `claude-models`, `mcp-servers`, `claude-tools` |
| `design` | `claude-models`, `mcp-servers`, `claude-tools` |
| `content-voice` | `claude-models`, `claude-tools` |
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
