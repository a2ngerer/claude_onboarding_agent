---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-04-29
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias              | Context | Typical use case |
|--------|-----------------------------|--------------------|---------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`  | 1M      | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`| 1M      | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5` | 200k    | Fast, cheap, high-volume tasks and subagents |

**Tokenizer note:** Opus 4.7 uses a new tokenizer — 1M tokens ≈ 555k words (vs. ≈ 750k words for Sonnet 4.6 with the older tokenizer).

## Extended and adaptive thinking

| Model       | Extended thinking | Adaptive thinking |
|-------------|-------------------|-------------------|
| Opus 4.7    | No                | Yes               |
| Sonnet 4.6  | Yes               | Yes               |
| Haiku 4.5   | Yes               | No                |

## Deprecated

Do not use these IDs in new code or configs. `claude-sonnet-4-20250514` and `claude-opus-4-20250514` retire on **June 15 2026**.

- `claude-sonnet-4-20250514` (retiring June 15 2026 — migrate to `claude-sonnet-4-6`)
- `claude-opus-4-20250514` (retiring June 15 2026 — migrate to `claude-opus-4-7`)
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
- The Claude 4.x family does not use `-latest` style aliases; the alias equals the version ID (e.g. `claude-opus-4-7`).
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7 context is 1M tokens but uses a denser tokenizer — budget token counts accordingly.
