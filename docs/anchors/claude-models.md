---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-30
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. The newest flagship is **Opus 4.8**. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

> Starting with the Claude 4.6 generation, model IDs use a dateless format that is a pinned snapshot, not an evergreen pointer.

## Model IDs

| Tier   | Model ID                    | Alias                 | Context | Max output | Typical use case |
|--------|-----------------------------|-----------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-8`           | (dateless, pinned)    | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`   | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`    | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

## Legacy (still available, not recommended for new code)

- `claude-opus-4-7` — 1M context, 128k output; previous Opus flagship.
- `claude-opus-4-6`, `claude-sonnet-4-5-20250929`, `claude-opus-4-5-20251101`, `claude-opus-4-1-20250805` — older Claude 4 variants.

## Deprecated

Do not use in new code or configs; migrate before retirement date.

**Retiring June 15, 2026:**
- `claude-sonnet-4-20250514` → migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` → migrate to `claude-opus-4-8`

**Already retired (do not use):**
- `claude-3-opus-20240229`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Both dated IDs (`claude-haiku-4-5-20251001`) and dateless IDs (`claude-sonnet-4-6`, `claude-opus-4-8`) are pinned snapshots — neither moves silently.
- Prefer dateless IDs for Claude 4.6-generation models and later; dated IDs for earlier generations.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
