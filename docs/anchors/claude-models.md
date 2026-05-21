---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-21
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

Starting with the 4.6 generation, dateless model IDs are pinned snapshots, not evergreen pointers. There are no `claude-*-latest` aliases for these models.

## Deprecated / retiring

Do not use these IDs in new code or configs. They will stop working on their retirement date.

- `claude-sonnet-4-20250514` — **retiring June 15, 2026** — migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` — **retiring June 15, 2026** — migrate to `claude-opus-4-7`
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Fast mode (Claude Code, default since v2.1.142):** `claude-opus-4-7`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the dateless pinned ID (`claude-sonnet-4-6`) over any `-latest` alias — those aliases do not exist for the 4.6+ generation.
- Opus 4.7 uses a new tokenizer that requires ~1.46× more tokens than 4.6 for the same text — budget for this when migrating.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
