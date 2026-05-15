---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-15
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

**Versioning note:** Starting with the Claude 4.6 generation, model IDs use a dateless format (`claude-sonnet-4-6`) that is a pinned snapshot — not an evergreen pointer. The alias resolves to the same snapshot; use the full ID in production to be explicit.

## Deprecated / retiring

Do not use these IDs in new code or configs.

- `claude-sonnet-4-20250514` — **retiring June 15, 2026**; migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` — **retiring June 15, 2026**; migrate to `claude-opus-4-7`
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **Fast mode (Claude Code):** `claude-opus-4-7` (switched from 4.6 in v2.1.142)
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- For Claude 4.6+ generation, the dateless model ID is itself a pinned snapshot. Still prefer the full explicit ID (`claude-sonnet-4-6`) over any alias in production.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7 uses a new tokenizer: token counts are ~1.46× higher for text vs. 4.6 — account for this in context budget planning.
