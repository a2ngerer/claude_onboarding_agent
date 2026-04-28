---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-04-28
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

> **Tokenizer note:** Opus 4.7 uses a new tokenizer that inflates token counts by ~1.0–1.35× compared to earlier models. Factor this into cost estimates.

## Capabilities

| Feature            | Opus 4.7 | Sonnet 4.6 | Haiku 4.5 |
|--------------------|----------|------------|-----------|
| Extended thinking  | No       | Yes        | Yes       |
| Adaptive thinking  | Yes      | Yes        | No        |

## Deprecated / legacy

Do not use these IDs in new code or configs.

**Retiring June 15, 2026:**
- `claude-sonnet-4-20250514` (alias `claude-sonnet-4-0`)
- `claude-opus-4-20250514` (alias `claude-opus-4-0`)

**Legacy (available but not recommended for new work):**
- `claude-opus-4-6`, `claude-sonnet-4-5-20250929`, `claude-opus-4-5-20251101`, `claude-opus-4-1-20250805`

**Retired (will stop working):**
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **dated ID** (`claude-haiku-4-5-20251001`) over an alias in production — aliases move silently.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7 supports `xhigh` effort level (between `high` and `max`); set via `effortLevel` in settings or `/effort`.
