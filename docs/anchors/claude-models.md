---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-22
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Max out | Typical use case |
|--------|-----------------------------|---------------------|---------|---------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | 128k    | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | 64k     | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k     | Fast, cheap, high-volume tasks and subagents |

Starting with the 4.6 generation, model IDs use a dateless format that is a **pinned snapshot**, not an evergreen pointer — there are no separate `claude-opus-latest` style aliases for current models. Haiku still carries a date in its ID; its alias strips it.

Opus 4.7 uses a new tokenizer: 1M tokens ≈ 555 k words (vs. ~150 k words under the old 200k-context models). Token consumption may increase 1.0–1.35× when migrating prompts from older models.

## Deprecated

### Retiring June 15, 2026 — migrate before this date

- `claude-sonnet-4-20250514` → migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` → migrate to `claude-opus-4-7`

### No longer recommended (use current 4.x family instead)

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
- **Fast Mode (Claude Code, since v2.1.142):** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus when quality demands it.
- **Effort level `xhigh`:** available only on Opus 4.7 (sits between `high` and `max`).

## Tips

- For Haiku, prefer the **dated ID** (`claude-haiku-4-5-20251001`) over the alias in production; for Opus 4.7 and Sonnet 4.6 the dateless ID is already a pinned snapshot.
- When migrating to Opus 4.7, re-run your eval suite: the new tokenizer changes token counts and prompts tuned for older models may need adjustment.
