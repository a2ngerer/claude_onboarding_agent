---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-08
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. `claude-opus-4-8` is the current top-tier model; `claude-sonnet-4-6` is the recommended balanced default. Starting with the 4.6 generation, model IDs use a dateless format and are pinned snapshots — there are no evergreen `*-latest` aliases.

## Model IDs

| Tier   | Model ID                    | Alias                     | Context | Typical use case |
|--------|-----------------------------|---------------------------|---------|------------------|
| Opus   | `claude-opus-4-8`           | `claude-opus-4-8`         | 1M      | Hardest reasoning, deep code analysis, high-autonomy agentic work |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`       | 1M      | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`        | 200k    | Fast, cheap, high-volume tasks and subagents |

`claude-opus-4-8` defaults to `effort: high` on all surfaces including Claude Code. Set `effort` explicitly to use a different level.

## Legacy (still available)

| Model ID                       | Context | Notes |
|--------------------------------|---------|-------|
| `claude-opus-4-7`              | 1M      | Previous Opus generation; adaptive thinking |
| `claude-opus-4-6`              | 1M      | Extended thinking |
| `claude-sonnet-4-5-20250929`   | 200k    | Extended thinking |

## Deprecated

Do not use these IDs in new code or configs. Retire by the dates shown.

- `claude-opus-4-1-20250805` — retire **2026-08-05**
- `claude-sonnet-4-20250514` — retire **2026-06-15**
- `claude-opus-4-20250514` — retire **2026-06-15**
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-opus-4-8` (default since v2.1.154)
- **Balanced coding and tasks:** `claude-sonnet-4-6`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus 4.8 only when quality demands it.

## Tips

- For 4.6+ models the ID is already a dateless pinned snapshot — the alias and the ID are the same string; no need to choose between them.
- `claude-opus-4-8` defaults to `effort: high`; set `effort: low` or `effort: medium` in cost-sensitive contexts.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
