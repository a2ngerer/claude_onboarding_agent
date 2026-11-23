---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-23
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.2 is the highest-capability generally available model; Opus 5.5 is the recommended starting point for most workloads. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

All IDs are pinned snapshots (dateless IDs included). Adaptive thinking is used on all current models; `temperature`/`top_p`/`top_k` are removed in API version `2026-10-21`.

| Tier   | Model ID           | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|--------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2` | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`  | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; recommended starting point |
| Sonnet | `claude-sonnet-5-5`| `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence |
| Haiku  | `claude-haiku-5-5` | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | High-volume, latency-sensitive tasks, classification, routing, subagents |

`claude-mythos-5-2` is the Fable-class model without dual-use safety measures; limited availability via Anthropic verification programs, not for general use. Earlier 5.x IDs (`claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`) remain active.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Update subagent definitions too.

- `claude-opus-4-5` / `claude-opus-4-5-20251101` — deprecated 2026-11-23, **retires 2027-01-22** (use `claude-opus-5-5`)
- `claude-sonnet-4-5` / `claude-sonnet-4-5-20250929` — deprecated, **retires 2026-11-30 (imminent)** (use `claude-sonnet-5-5`)
- `claude-haiku-4-5-20251001` — active, not retiring sooner than 2026-10-15 (use `claude-haiku-5-5`)
- `claude-mythos-preview` — deprecated 2026-06-09
- Retired: `claude-opus-4-1-20250805` (2026-08-05), `claude-opus-4-20250514` and `claude-sonnet-4-20250514` (2026-06-15), `claude-3-haiku-20240307`, `claude-3-5-haiku-20241022`, `claude-3-7-sonnet-20250219`, and all Claude 3 / 3.5 Sonnet, Opus 3, Claude 2 and Instant IDs
- Legacy but active: `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6`

Anthropic gives at least 60 days' notice before retiring a public model. In Claude Code, a `fallbackModel` chain switches to the next model when the selected one is retired.

## Tokenizer note

Models since Opus 4.7 use a tokenizer that yields roughly 30% more tokens for the same text than earlier models. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / most workloads:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use the dateless IDs for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Batch API is 50% off; prompt-cache reads cost a fraction of base input price.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
