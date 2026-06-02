---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-02
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias                       | Context | Max output | Typical use case |
|--------|-----------------------------|-----------------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-8`           | `claude-opus-4-8`           | 1M      | 128k       | Hardest reasoning, long-horizon agentic coding; `effort` defaults to `high` |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`         | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`          | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

**Opus 4.8 effort:** `effort` defaults to `high` on all surfaces (API and Claude Code). Set it explicitly if you need a different level (`/effort xhigh` enables an extra-high tier).

## Legacy (still available, not recommended for new code)

| Model ID | Context | Notes |
|----------|---------|-------|
| `claude-opus-4-7` | 1M | Previous Opus; new tokenizer uses 1.0–1.35× more tokens than 4.6 for same content |
| `claude-opus-4-6` | 1M | — |
| `claude-sonnet-4-5-20250929` | 200k | — |
| `claude-opus-4-5-20251101` | 200k | — |

## Deprecated (will be retired)

Do not use in new code. Migrate before the retirement date.

| Model ID | Retirement | Migrate to |
|----------|-----------|------------|
| `claude-sonnet-4-20250514` | June 15, 2026 | `claude-sonnet-4-6` |
| `claude-opus-4-20250514`   | June 15, 2026 | `claude-opus-4-8` |
| `claude-3-opus-20240229`   | Retired | `claude-opus-4-8` |
| `claude-3-5-sonnet-20241022` | Retired | `claude-sonnet-4-6` |
| `claude-3-5-haiku-20241022`  | Retired | `claude-haiku-4-5-20251001` |
| `claude-2.1`, `claude-instant-1.2` | Retired | — |

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-8` (note: high effort by default — costs more than Opus 4.7)
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Starting with Claude 4.6, model IDs use a dateless format that is a pinned snapshot, not an evergreen pointer. Prefer the explicit ID over any alias in production.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7 uses a new tokenizer — expect 1.0–1.35× more tokens than Opus 4.6 for the same content, even though pricing is unchanged.
- Check `platform.claude.com/docs/en/about-claude/model-deprecations` before a project goes to production to confirm the pinned ID is not near retirement.
