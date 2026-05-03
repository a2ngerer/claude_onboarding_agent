---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-03
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias                | Context | Max output | Typical use case                                         |
|--------|-----------------------------|----------------------|---------|------------|----------------------------------------------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`    | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`  | 1M      | 64k        | Balanced default — most coding and general tasks         |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`   | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents             |

Opus 4.7 supports **adaptive thinking**. Sonnet 4.6 and Haiku 4.5 support **extended thinking**.

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date and generally point to weaker models than the current family.

- `claude-sonnet-4-20250514`, `claude-opus-4-20250514` — retiring **2026-06-15**
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

- Prefer the **dated ID** (`claude-haiku-4-5-20251001`) over an alias in production — aliases move silently.
- Opus 4.7 uses a new tokenizer; token counts run 1.0–1.35× higher than earlier models — re-budget accordingly and re-run eval suites when migrating.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Batch API supports up to 300k output tokens for Opus 4.7, Opus 4.6, and Sonnet 4.6 (requires `output-300k-2026-03-24` beta header).
