---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-20
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.2 is the highest-capability generally available tier; Opus 5.5 is the recommended starting point for most workloads. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | High-volume, latency-sensitive tasks, classification, routing, subagent scans |

`claude-mythos-5-2` is the Fable-class model without dual-use safety measures. It is limited availability (verification program only) and not recommended for general use. Older 5.x IDs (`claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`) remain active.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Aliases are the only moving pointers; use a full ID for reproducibility across alias promotions.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` (and `claude-sonnet-4-5`) — deprecated, **retires 2026-11-30**; replacement `claude-sonnet-5-5`
- `claude-opus-4-5-20251101` — active, not retiring sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — active, not retiring sooner than 2026-10-15; prefer `claude-haiku-5-5`
- `claude-mythos-preview` — deprecated 2026-06-09
- Legacy but active: `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6`
- Retired: `claude-opus-4-1-20250805` (2026-08-05), `claude-opus-4-20250514` and `claude-sonnet-4-20250514` (2026-06-15), `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-*`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-2.x`, `claude-instant-*`

## API parameter note

`temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` (400 error); earlier versions reject non-default values on Claude 4.7+ models. Omit them and steer behavior via prompting and `effort`.

## Tokenizer note

Opus 4.7 and later models (including all 5.x) use a tokenizer that produces roughly 30% more tokens for the same text than pre-4.7 models. Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads and deep agentic coding:** `claude-opus-5-5`
- **Everyday speed/cost balance (Claude Code Sonnet tier):** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Update model references everywhere, including subagent definitions, when a model is deprecated.
