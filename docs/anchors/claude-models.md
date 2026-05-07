---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-07
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias                | Context | Typical use case |
|--------|-----------------------------|----------------------|---------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`    | 1M      | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`  | 1M      | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`   | 200k    | Fast, cheap, high-volume tasks and subagents |

Starting with the Claude 4.6 generation, model IDs use a dateless format that is itself a pinned snapshot — not an evergreen pointer. Aliases for these models resolve to the same pinned ID and do not roll forward silently.

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date.

- `claude-sonnet-4-20250514` — retiring June 15, 2026; migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` — retiring June 15, 2026; migrate to `claude-opus-4-7`
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

- For Claude 4.6+ generation models, the dateless ID is already a pinned snapshot — no separate alias needed. For pre-4.6 models (e.g. `claude-haiku-4-5-20251001`), prefer the dated ID over the short alias to prevent silent model changes.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7 has a 1M-token context window with a new tokenizer (~555k words / ~2.5M unicode chars). Sonnet 4.6 also has a 1M-token context window.
