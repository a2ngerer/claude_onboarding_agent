---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-01
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Typical use case |
|--------|-----------------------------|---------------------|---------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | Fast, cheap, high-volume tasks and subagents |

**Note:** Opus 4.7 uses a new tokenizer; the same source text produces ~1.0–1.35× more tokens than on older models.

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date and generally point to weaker models than the current family.

**Retiring June 15, 2026:**
- `claude-sonnet-4-20250514` (alias: `claude-sonnet-4-0`)
- `claude-opus-4-20250514` (alias: `claude-opus-4-0`)

**Already retired / avoid:**
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
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- The 1M context window on Opus 4.7 and Sonnet 4.6 accepts large codebases or long document chains in one pass.
- Migrate away from `claude-sonnet-4-20250514` and `claude-opus-4-20250514` before June 15, 2026.
