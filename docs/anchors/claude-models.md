---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-19
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias                | Context | Max output | Typical use case |
|--------|-----------------------------|----------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`    | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`  | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`   | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

Starting with the 4.6 generation, model IDs are dateless pinned snapshots (not evergreen pointers). For Opus 4.7 and Sonnet 4.6, the alias equals the ID. For Haiku 4.5 and older models, aliases are separate convenience pointers.

## Deprecated

Do not use these IDs in new code or configs.

**Retiring June 15, 2026 — migrate now:**
- `claude-sonnet-4-20250514` (alias: `claude-sonnet-4-0`) → migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` (alias: `claude-opus-4-0`) → migrate to `claude-opus-4-7`

**Older — already retired or not recommended:**
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
- **Claude Code fast mode:** defaults to `claude-opus-4-7` (override with `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1`)
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- For Haiku, prefer the **dated ID** (`claude-haiku-4-5-20251001`) in production — the alias (`claude-haiku-4-5`) may resolve to future patch releases.
- For Opus 4.7 and Sonnet 4.6, alias and ID are identical; either is safe.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
