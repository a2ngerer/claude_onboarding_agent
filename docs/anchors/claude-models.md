---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-06
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs below unless a project has pinned an older version for a specific reason. Starting with the 4.6 generation, model IDs are dateless pinned snapshots — not evergreen pointers.

## Model IDs

| Tier   | Model ID              | Context | Max output | Typical use case |
|--------|-----------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-8`     | 1M      | 128k       | Hardest reasoning, long-horizon agentic coding, high-autonomy work |
| Sonnet | `claude-sonnet-4-6`   | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | 200k | 64k   | Fast, cheap, high-volume tasks and subagents |

## Legacy (still available)

Consider migrating to current models:

| Model ID | Notes |
|---|---|
| `claude-opus-4-7` | Previous Opus tier; new tokenizer increases token counts 1.0–1.35× |
| `claude-opus-4-6` | Earlier Opus with extended thinking |
| `claude-sonnet-4-5-20250929` | Previous Sonnet tier |

## Deprecated

Do not use in new code or configs — retire these immediately.

- `claude-opus-4-1-20250805` — retiring **2026-08-05**
- `claude-sonnet-4-20250514` — retiring **2026-06-15**
- `claude-opus-4-20250514` — retiring **2026-06-15**
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
- **Deep reasoning / long-horizon agentic tasks:** `claude-opus-4-8`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **pinned ID** over aliases in production — 4.6+ IDs are already pinned snapshots; pre-4.6 aliases can move silently.
- `claude-opus-4-8` defaults to `effort: high` on all surfaces (API and Claude Code) — set `effort` explicitly if you need a different level.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Batch API supports up to 300k output tokens for Opus 4.8 and Sonnet 4.6 with the `output-300k-2026-03-24` beta header.
