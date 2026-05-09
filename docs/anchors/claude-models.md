---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-09
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | API alias           | Context | Max output |
|--------|-----------------------------|---------------------|---------|------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | 128k       |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | 64k        |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k        |

**Note on aliases:** Starting with the 4.6 generation, model IDs are dateless pinned snapshots; there are no evergreen `*-latest` pointer aliases for current models. Use the model ID directly in production.

**Note on Opus 4.7 tokenizer:** Opus 4.7 uses a new tokenizer — input token counts run approximately 1.0–1.35× higher than previous models for the same text. Pricing per token is unchanged.

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date.

### Retiring June 15, 2026
- `claude-sonnet-4-20250514` → migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` → migrate to `claude-opus-4-7`

### Previously deprecated (may already be retired)
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

- Prefer the dated ID (`claude-haiku-4-5-20251001`) or the dateless snapshot ID (`claude-sonnet-4-6`) over any alias in production.
- For 4.6+ models, the API alias is identical to the model ID; use either form.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Use the [Models API](https://platform.claude.com/docs/en/api/models/list) to query `max_input_tokens`, `max_tokens`, and capabilities programmatically.
