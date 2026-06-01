---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-01
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias                | Context | Max output | Notes |
|--------|-----------------------------|----------------------|---------|------------|-------|
| Opus   | `claude-opus-4-8`           | `claude-opus-4-8`    | 1M      | 128k       | Default effort: `xhigh`; Adaptive thinking |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`  | 1M      | 64k        | Balanced default; Extended + Adaptive thinking |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`   | 200k    | 64k        | Fast, cheap; no Adaptive thinking |

## Legacy (still available — migrate when possible)

| Model ID                     | Context | Notes |
|------------------------------|---------|-------|
| `claude-opus-4-7`            | 1M      | Extended + Adaptive thinking; updated tokenizer (~1.46× text token inflation vs 4.6) |
| `claude-opus-4-6`            | 1M      | Extended + Adaptive thinking |
| `claude-sonnet-4-5-20250929` | 200k    | Extended thinking |

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date.

- `claude-sonnet-4-20250514` — **retires June 15, 2026** (migrate to `claude-sonnet-4-6`)
- `claude-opus-4-20250514` — **retires June 15, 2026** (migrate to `claude-opus-4-8`)
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1` / `claude-2.0` / `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / long-horizon agentic work:** `claude-opus-4-8` (defaults to `effort: xhigh`)
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Starting with the 4.6 generation, model IDs are pinned snapshots even without a date suffix — they do not float.
- Prefer the **explicit ID** over an alias in production — both are pinned for 4.x, but being explicit signals intent.
- Opus 4.7 uses a new tokenizer causing ~1.46× token inflation for text inputs; account for this when comparing costs with 4.6.
- Set `effort` explicitly on Opus 4.8 if you want less than `xhigh`; otherwise it defaults to maximum effort.
- When migrating between families, re-run your eval suite; prompts tuned for one model may need light adjustment.
- Batch API supports up to 300k output tokens for Opus 4.8 and Sonnet 4.6 via the `output-300k-2026-03-24` beta header.
