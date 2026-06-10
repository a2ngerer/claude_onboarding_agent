---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-10
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x and Fable 5 are the current tiers as of `last_updated`. Starting with the 4.6 generation, model IDs are dateless pinned snapshots — they do not move silently like pre-4.6 aliases. Default to the IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier    | Model ID                    | Context | Typical use case |
|---------|-----------------------------|---------|-----------------|
| Fable 5 | `claude-fable-5`            | 1M      | Highest capability — most demanding reasoning and long-horizon agentic work |
| Opus    | `claude-opus-4-8`           | 1M      | Complex reasoning, deep code analysis, agentic workflows |
| Sonnet  | `claude-sonnet-4-6`         | 1M      | Balanced default — most coding and general tasks |
| Haiku   | `claude-haiku-4-5-20251001` | 200k    | Fast, cheap, high-volume tasks and subagents |

Claude Mythos 5 (`claude-mythos-5`) is available only via Project Glasswing (invitation-only, no self-serve).

Note: models from Opus 4.7 onwards use a new tokenizer that produces ~30% more tokens than pre-4.7 for the same text. Budget API costs accordingly when migrating.

## Deprecated / Legacy

Do not use these IDs in new code. **(retiring)** entries have announced end-of-life dates.

- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — **(retiring June 15, 2026)**
- `claude-opus-4-1-20250805` — **(retiring August 5, 2026)**
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **Highest capability work:** `claude-fable-5`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus 4.8 or Fable 5 only when quality demands it.

## Tips

- Prefer the **pinned model ID** over an alias in production — aliases can resolve to different versions across API surfaces.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
