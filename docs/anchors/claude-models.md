---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-28
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family. Default to the latest IDs below unless a project pins an older version for a specific reason.

## Model IDs

Starting with the 4.6 generation, model IDs use a dateless format that is also a pinned snapshot — the alias equals the model ID, not an evergreen pointer.

| Tier   | Model ID                    | Alias                   | Context | Typical use case |
|--------|-----------------------------|-------------------------|---------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`       | 1M      | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`     | 1M      | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`      | 200k    | Fast, cheap, high-volume tasks and subagents |

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date and generally point to weaker models than the current family.

**Retiring June 15, 2026:**
- `claude-sonnet-4-20250514`
- `claude-opus-4-20250514`

**Previously retired:**
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
- **Fast mode (Claude Code):** uses `claude-opus-4-7` as of v2.1.142.

## Tips

- Prefer the **dated ID** (`claude-haiku-4-5-20251001`) for Haiku; for Opus 4.7 and Sonnet 4.6 the dateless ID is already a fixed snapshot.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7 uses a new tokenizer — expect approximately 5–35% more tokens than Opus 4.6 for the same content.
