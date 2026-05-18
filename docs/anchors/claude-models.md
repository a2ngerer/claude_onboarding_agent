---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-18
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias              | Context | Max output | Typical use case |
|--------|-----------------------------|--------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | `claude-opus-4-7`  | 1M      | 128k       | Hardest reasoning, agentic coding, deep analysis |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`| 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5` | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

Starting with the 4.6 generation, dateless IDs (`claude-opus-4-7`, `claude-sonnet-4-6`) are pinned snapshots, not evergreen pointers. Only Haiku 4.5 still uses a dated ID.

**Opus 4.7 tokenizer note:** Uses a new tokenizer that increases token counts by ~1.0–1.35× compared to older models. Re-benchmark costs after migration.

## Legacy models (available but not recommended for new code)

| Model ID | Context | Notes |
|---|---|---|
| `claude-opus-4-6` | 1M | Previous Opus generation |
| `claude-sonnet-4-5-20250929` | 200k | |
| `claude-opus-4-5-20251101` | 200k | |
| `claude-opus-4-1-20250805` | 200k | |

## Deprecated (retiring June 15, 2026)

- `claude-sonnet-4-20250514` (alias `claude-sonnet-4-0`) → migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` (alias `claude-opus-4-0`) → migrate to `claude-opus-4-7`

## Do not use in new code

- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic coding:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- For 4.5-generation and older, aliases are evergreen pointers; prefer dated IDs (`claude-haiku-4-5-20251001`) in production. For 4.6+, the dateless ID is also a pinned snapshot.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Fast mode in Claude Code now uses Opus 4.7 by default; set `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` to pin to Opus 4.6.
- Batch API: Opus 4.7, Opus 4.6, and Sonnet 4.6 support up to 300k output tokens via the `output-300k-2026-03-24` beta header.
