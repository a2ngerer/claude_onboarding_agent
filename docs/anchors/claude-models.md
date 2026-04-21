---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-04-21
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 1
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias              | Context | Typical use case |
|--------|-----------------------|--------------------|---------|------------------|
| Opus   | `claude-opus-4-7`     | claude-opus-latest | 200k    | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`   | claude-sonnet-latest | 200k  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | claude-haiku-latest | 200k | Fast, cheap, high-volume tasks and subagents |

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date and generally point to weaker models than the current family.

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
