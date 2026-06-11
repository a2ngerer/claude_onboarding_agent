---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-11
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude Fable 5 (`claude-fable-5`) is now generally available as the most capable widely released model (GA: 2026-06-09). The 4.x family (Opus 4.8, Sonnet 4.6, Haiku 4.5) is the everyday workhorse. Default to the IDs below unless a project pins an older version.

## Model IDs

| Tier     | Model ID                    | Context | Typical use case |
|----------|-----------------------------|---------|------------------|
| Fable 5  | `claude-fable-5`            | 1M      | Highest capability; adaptive thinking always on; no separate extended thinking |
| Opus     | `claude-opus-4-8`           | 1M      | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet   | `claude-sonnet-4-6`         | 1M      | Balanced default — most coding and general tasks |
| Haiku    | `claude-haiku-4-5-20251001` | 200k    | Fast, cheap, high-volume tasks and subagents |

**Tokenizer note:** Fable 5, Opus 4.8, and all models since Opus 4.7 use a newer tokenizer — the same text produces ~30% more tokens than pre-4.7 models.

## Deprecated

Do not use these IDs in new code or configs. They will stop working on their retirement date.

- `claude-opus-4-1-20250805` — retiring **2026-08-05**; migrate to Opus 4.8
- `claude-sonnet-4-20250514`, `claude-opus-4-20250514` — retiring **2026-06-15**
- `claude-3-opus-20240229`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Maximum capability / frontier tasks:** `claude-fable-5`
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus 4.8 or Fable 5 when quality demands it.

## Tips

- Prefer the **dated ID** (`claude-sonnet-4-6`) over an alias in production — aliases move silently.
- Fable 5 does not support extended thinking separately; adaptive thinking is always on.
- Opus 4.8 defaults to `effort: high` on all surfaces; set `effort` explicitly if you need a different level.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
