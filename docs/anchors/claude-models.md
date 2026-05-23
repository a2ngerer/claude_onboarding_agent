---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-23
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias              | Context | Max Output | Typical use case |
|--------|-----------------------------|--------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`  | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`| 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5` | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

Starting with the 4.6 generation, model IDs use a dateless format that is a pinned snapshot — not an evergreen pointer. There are no `-latest` aliases for Claude 4.6+ models.

## Deprecated (do not use in new code)

Models with a retirement date will stop working on that date.

- `claude-sonnet-4-20250514` — retiring **June 15, 2026**; migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` — retiring **June 15, 2026**; migrate to `claude-opus-4-7`
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Legacy (callable but not recommended)

Consider migrating to the latest family:

- `claude-opus-4-6` — 1M context, 128k output
- `claude-sonnet-4-5-20250929`, `claude-opus-4-5-20251101`, `claude-opus-4-1-20250805` — 200k context

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Opus 4.7 and Sonnet 4.6 have **1M token** context windows; Haiku 4.5 has 200k.
- For 4.6+ models the ID and alias are identical pinned snapshots — no `-latest` alias exists.
- For older models with date-stamped IDs, prefer the **dated ID** over an alias in production — aliases move silently.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 4.6 and Haiku 4.5 support extended thinking; Opus 4.7 uses adaptive thinking instead.
