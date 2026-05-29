---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-29
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
| Opus   | `claude-opus-4-8`           | claude-opus-latest   | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | claude-sonnet-latest | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | claude-haiku-latest  | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

**Still available (legacy):** `claude-opus-4-7` (1M context, 128k output) — superseded by Opus 4.8 but not yet deprecated.

## Deprecated

Do not use these IDs in new code or configs.

**Retiring June 15, 2026 — migrate now:**
- `claude-sonnet-4-20250514` (alias: `claude-sonnet-4-0`)
- `claude-opus-4-20250514` (alias: `claude-opus-4-0`)

**Already retired or no longer recommended:**
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
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **versioned ID** (`claude-sonnet-4-6`, `claude-opus-4-8`) over an alias in production — aliases move silently.
- Opus 4.8 defaults to `effort: high` on all API surfaces including Claude Code; set `effort` explicitly to use a lower level.
- Opus 4.7 uses a new tokenizer: same text costs ~1.46× more tokens than Opus 4.6; re-check context budgets when migrating.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
