---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-25
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Max output |
|--------|-----------------------------|---------------------|---------|------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | 128k       |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | 64k        |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k        |

> Claude 4.x aliases equal the versioned ID — there are no `-latest` aliases for this generation. The `-latest` aliases only existed for Claude 3.x.

## Deprecated

Do not use these IDs in new code or configs. The 4.0 series retires **June 15, 2026**.

| ID | Notes |
|----|-------|
| `claude-sonnet-4-20250514` | Deprecated — migrate to `claude-sonnet-4-6` before 2026-06-15 |
| `claude-opus-4-20250514` | Deprecated — migrate to `claude-opus-4-7` before 2026-06-15 |
| `claude-3-opus-20240229` | Claude 3.x — stop using |
| `claude-3-5-sonnet-20241022` | Claude 3.5 — stop using |
| `claude-3-5-haiku-20241022` | Claude 3.5 — stop using |
| `claude-3-haiku-20240307` | Claude 3.x — stop using |
| `claude-2.1`, `claude-2.0`, `claude-instant-1.2` | Legacy — stop using |

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **dated ID** over an alias in production — aliases move silently.
- Opus 4.7 and Sonnet 4.6 have a **1M-token context window**; Haiku 4.5 is 200k.
- Opus 4.7 uses a **new tokenizer** (different token counts for the same text vs. earlier models — verify budgets when migrating).
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
