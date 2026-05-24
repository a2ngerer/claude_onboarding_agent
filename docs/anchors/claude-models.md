---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-24
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Max output | Knowledge cutoff |
|--------|-----------------------------|---------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | 128k       | Jan 2026         |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | 64k        | Aug 2025         |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k        | Feb 2025         |

Notes:
- Starting with the 4.6 generation, model IDs are dateless pinned snapshots — not evergreen pointers. Aliases for Opus 4.7 and Sonnet 4.6 are identical to their IDs.
- Opus 4.7 supports **adaptive thinking** but not extended thinking; Sonnet 4.6 and Haiku 4.5 support extended thinking.
- Opus 4.7 has an exclusive `xhigh` effort level (between `high` and `max`). Set via `effortLevel` in settings or `--effort xhigh` at the CLI.
- Fast Mode defaults to Opus 4.7.

## Legacy / deprecated

Available but should not be used in new code; migrate before retirement dates.

- `claude-opus-4-6`, `claude-sonnet-4-5-20250929`, `claude-opus-4-5-20251101`, `claude-opus-4-1-20250805` — available, consider migrating
- `claude-sonnet-4-20250514` — **deprecated, retiring June 15 2026**
- `claude-opus-4-20250514` — **deprecated, retiring June 15 2026**
- `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-3-opus-20240229` and older — do not use
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2` — do not use

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **dated ID** (`claude-haiku-4-5-20251001`) over an alias in production — for pre-4.6 models, aliases move silently to newer snapshots.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Query capabilities and token limits programmatically via the Models API (`GET /v1/models`).
