---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-12
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude Fable 5 is the highest publicly available tier as of `last_updated`. The 4.x family (Opus 4.8, Sonnet 4.6, Haiku 4.5) is the standard workhorse. Default to the IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier    | Model ID                    | Context | Typical use case |
|---------|-----------------------------|---------|------------------|
| Fable 5 | `claude-fable-5`            | 1M      | Hardest reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus    | `claude-opus-4-8`           | 1M      | Complex reasoning, deep code analysis, agentic coding; `effort` defaults to `high` |
| Sonnet  | `claude-sonnet-4-6`         | 1M      | Balanced default — most coding and general tasks |
| Haiku   | `claude-haiku-4-5-20251001` | 200k    | Fast, cheap, high-volume tasks and subagents |

Starting with the 4.6 generation, all model IDs are dateless pinned snapshots — not evergreen pointers. Aliases like `claude-opus-latest` still resolve for pre-4.6 models only; prefer explicit IDs in all production code.

## Deprecated

Do not use these IDs in new code or configs.

- `claude-opus-4-1-20250805` — retiring 2026-08-05; migrate to `claude-opus-4-8`
- `claude-sonnet-4-20250514` — retiring 2026-06-15; migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` — retiring 2026-06-15; migrate to `claude-opus-4-8`
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-8` (effort defaults to `high` on all surfaces)
- **Maximum capability:** `claude-fable-5` ($10/$50 per MTok input/output)
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus or Fable only when quality demands it.

## Tips

- Prefer the **model ID** over an alias in production — aliases are only maintained for pre-4.6 models.
- Opus 4.8 and Fable 5 use the Opus 4.7 tokenizer: ~30% more tokens vs. earlier models for the same text.
- Fable 5 context is 1M with 128k max output; Opus 4.8 and Sonnet 4.6 are also 1M; Haiku 4.5 is 200k.
- Opus 4.8 `effort` defaults to `high` — set it explicitly if you need a different level.
- On the Batch API, Opus 4.8 and Sonnet 4.6 support up to 300k output tokens with the `output-300k-2026-03-24` beta header.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
