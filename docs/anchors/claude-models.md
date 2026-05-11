---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-11
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Context | Max output | Typical use case |
|--------|-----------------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

> **Aliases:** Starting with Claude 4.6, model IDs are pinned snapshots with no separate `-latest` alias. Use the model ID directly in code.
> **Tokenizer note:** Claude Opus 4.7 uses a new tokenizer (~1.46× more tokens per text vs. Opus 4.6); re-check costs and context budgets before migrating.

## Deprecated / legacy

Available but prefer the current family above. Migrate before retirement dates.

| Model ID | Retirement |
|---|---|
| `claude-opus-4-6` | No date announced |
| `claude-sonnet-4-5-20250929` | No date announced |
| `claude-sonnet-4-20250514` | **June 15 2026** |
| `claude-opus-4-20250514` | **June 15 2026** |

Do not use Claude 3.x or Claude 2.x IDs in new code — those generations are retired or past their end-of-support date.

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **full model ID** (`claude-sonnet-4-6`) in production — there are no evergreen aliases in the 4.x generation.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- For Opus 4.7 migration: the new tokenizer inflates token counts ~40% for text inputs — update context budgets and cost estimates before switching.
