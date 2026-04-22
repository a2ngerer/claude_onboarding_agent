---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-04-22
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Max output | Typical use case |
|--------|-----------------------------|---------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`   | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic coding |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6` | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

**Opus 4.7 tokenizer note:** Uses a new tokenizer — the same prompt costs roughly 1.0–1.35× more tokens than on older models. Budget accordingly.

**Opus 4.7 effort levels:** Supports `low`, `medium`, `high`, `xhigh`, and `max`. `xhigh` sits between `high` and `max` and was added April 2026.

## Pricing

| Tier       | Input (per MTok) | Output (per MTok) |
|------------|-----------------|-------------------|
| Opus 4.7   | $5              | $25               |
| Sonnet 4.6 | $3              | $15               |
| Haiku 4.5  | $1              | $5                |

## Knowledge cutoffs

| Model      | Reliable cutoff | Training data cutoff |
|------------|----------------|---------------------|
| Opus 4.7   | Jan 2026       | Jan 2026            |
| Sonnet 4.6 | Aug 2025       | Jan 2026            |
| Haiku 4.5  | Feb 2025       | Jul 2025            |

## Deprecated

Do not use these IDs in new code or configs.

**Retiring June 15, 2026** — migrate before then:
- `claude-sonnet-4-20250514` → replace with `claude-sonnet-4-6`
- `claude-opus-4-20250514` → replace with `claude-opus-4-7`

**Already retired** (will stop working; point to weaker models):
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic coding:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **dated ID** (`claude-sonnet-4-6`, `claude-haiku-4-5-20251001`) over alias in production — some aliases move silently.
- Opus 4.7 and Sonnet 4.6 share a 1M-token context window but Opus 4.7's new tokenizer means identical prompts cost more tokens; factor this into cost estimates.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
