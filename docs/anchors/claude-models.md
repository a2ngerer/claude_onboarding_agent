---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-10
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 / Fable 5.2 is the current family as of `last_updated`. Fable sits above Opus as the highest-capability tier. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason. Every Claude model ID is a pinned snapshot (dateless IDs included, from the 4.6 generation on).

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable` | 1M      | 128k       | $8 / $40                  | Demanding reasoning and long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Best balance of speed and intelligence — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / $0.50        | Fast, cheap, high-volume tasks: classification, extraction, routing, subagents |

`claude-mythos-5-2` is the same model as Fable 5.2 without dual-use safety measures. It is invitation-only and not recommended for general use.

All current models use adaptive thinking steered by the `effort` parameter. Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default (e.g. `fable` moved from Fable 5.1 to 5.2).

## ID pinning behavior

Undated model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them for stability; use aliases only when you want to follow promotions.

## Retirement commitments

Current models are not retiring sooner than: Haiku 5.5 — 2027-10-07, Sonnet 5.5 — 2027-09-28, Opus 5.5 — 2027-09-22, Fable 5.2 — 2027-11-09.

Legacy (still available, avoid in new configs): `claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`.

Opus 4.8 fast mode is deprecated and is removed on **2026-11-30** — migrate to Opus 5.5 to keep the speedup.

Retired or no longer listed — do not use: `claude-sonnet-4-0`, `claude-opus-4-0` (retired 2026-06-15), `claude-opus-4-1` (retired 2026-08-05), `claude-sonnet-4-5`, all `claude-3-*` and `claude-3-5-*` IDs, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`.

## Tokenizer note

Models from Opus 4.7 onward use a newer tokenizer: 1M tokens is roughly 555k words (older models: ~750k words). Factor this into cost estimates when migrating from older models. Prompt cache reads cost 10% of base input (5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.x).

## Defaults

- **Most workloads (starting point):** `claude-opus-5-5`
- **Everyday tasks and fast agentic coding:** `claude-sonnet-5-5`
- **Maximum capability / hardest reasoning:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use undated IDs (`claude-opus-5-5`) for production stability. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- At `max` effort Opus 5.5 can exhaust its 128k output budget without producing a final answer; prefer `high`/`xhigh` unless evals demand more.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
