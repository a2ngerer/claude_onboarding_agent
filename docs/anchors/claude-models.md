---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-17
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

**Alias note:** Starting with the 4.6 generation, model IDs use a dateless format that is also a pinned snapshot — there are no evergreen aliases like `claude-opus-latest`. The alias IS the pinned ID for 4.x; no silent drift is possible.

**Tokenizer note:** Opus 4.7 ships a new tokenizer. The same content encodes in ~1.46× more tokens than Opus 4.6. Recalculate token budgets and cost estimates when migrating from Opus 4.6.

## Deprecated

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
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Effort levels

Configurable via `/effort` or `effortLevel` in `settings.json`: `low`, `medium`, `high`, `xhigh`, `max`.
The `xhigh` level (between high and max) is Opus 4.7–only. Effort level is also exposed to hooks via `$CLAUDE_EFFORT`.

## Tips

- Prefer the **pinned ID** over any alias — for 4.x, the alias IS the pinned ID.
- When migrating from Opus 4.6 → 4.7, recalculate token budgets (new tokenizer, ~1.46× more tokens).
- When migrating between versions, re-run your eval suite; prompts tuned for one model may need light adjustment.
