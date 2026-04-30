---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-04-30
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Max output | Typical use case |
|--------|-----------------------------|---------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

Notes: Opus 4.7 uses a new tokenizer (≈1.46× more tokens per text unit than 4.6); budget context accordingly. Opus 4.7 supports an `xhigh` effort level (above `high`, below `max`).

## Legacy (still available — migration recommended)

These IDs still respond but are weaker or less efficient than the current family.

| ID | Notes |
|----|-------|
| `claude-opus-4-6` | predecessor to Opus 4.7; same price, lower intelligence |
| `claude-sonnet-4-5-20250929` | predecessor to Sonnet 4.6 |
| `claude-opus-4-5-20251101` | older Opus line |
| `claude-opus-4-1-20250805` | older Opus line |

## Deprecated (do not use — retiring)

`claude-sonnet-4-20250514` and `claude-opus-4-20250514` are deprecated and will be **retired June 15, 2026**. Migrate to Sonnet 4.6 and Opus 4.7 respectively before that date.

Older deprecated IDs (no longer recommended):

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

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **dated ID** (`claude-sonnet-4-6`) over an alias in production — aliases move silently.
- Opus 4.7 and Sonnet 4.6 both support 1M token contexts; this unlocks very large codebases and long sessions.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
