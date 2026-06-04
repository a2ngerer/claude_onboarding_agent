---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-04
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

Starting with the 4.6 generation, model IDs use a dateless format (`claude-sonnet-4-6`) that is itself a pinned snapshot — not a rolling pointer. Aliases for these models resolve to the same ID.

## Model IDs

| Tier   | Model ID                    | Context | Max output | Typical use case |
|--------|-----------------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-8`           | 1M      | 128k       | Hardest reasoning, long-horizon agentic coding (defaults to `effort: high`) |
| Sonnet | `claude-sonnet-4-6`         | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

## Deprecated / retiring

Do not use these IDs in new code or configs.

**Retiring June 15, 2026 — migrate now:**
- `claude-sonnet-4-20250514` → use `claude-sonnet-4-6`
- `claude-opus-4-20250514` → use `claude-opus-4-8`

**Superseded (still available but prefer the IDs above):**
- `claude-opus-4-7`

**Retired (will stop working):**
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-8` — defaults to `effort: high`; use `/effort xhigh` for hardest tasks
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- With the 4.6+ generation, the dateless ID (`claude-sonnet-4-6`) is already a pinned snapshot — no separate date suffix needed.
- On Opus 4.8, `effort` defaults to `high` on all surfaces including the API. Set it explicitly to use a lower level.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
