---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-12
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Fable sits above Opus as the highest-capability generally available tier. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

All current models share a 1M context window, 128k max output (synchronous API), adaptive thinking, and a Jun 2026 knowledge cutoff.

| Tier   | Model ID            | Alias    | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | $10 / $50                 | high   | Demanding reasoning and long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | $4 / $20                  | medium | Long-running agentic coding and knowledge work; start here for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | $2 / $10                  | high   | Best combination of speed and intelligence; everyday coding |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | $0.10 / $0.50 (≤100k prompt); $0.50 / $2.50 (>100k) | medium | High-volume, latency-sensitive tasks: classification, extraction, routing, subagent scans |

`claude-mythos-5-1` has Fable 5.1 pricing but is limited availability and not recommended for general use.

Prompt cache reads cost 10% of base input price (2.5% on Fable 5.1, 5% on Opus 5.5 and Sonnet 5.5); Batch API requests are 50% off.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them for stability without memorizing a dated ID. Aliases still move; use the full ID for reproducibility across alias promotions.

## Legacy and retiring

Legacy models still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`. Prefer the 5.5 IDs in new code.

Entries with a date stop working on that date (Anthropic-operated platforms):

- `claude-sonnet-4-5-20250929` — deprecated; **retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-opus-4-5-20251101` — not sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — not sooner than 2026-10-15 (replacement: `claude-haiku-5-5`)

Already retired — do not use: `claude-opus-4-1-20250805` (2026-08-05), `claude-opus-4-20250514` and `claude-sonnet-4-20250514` (2026-06-15), `claude-3-haiku-20240307`, `claude-3-5-haiku-20241022`, `claude-3-7-sonnet-20250219`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`.

`temperature`, `top_p`, and `top_k` return a 400 error when set to non-default values on Claude 4.7 and later; omit them. Manual extended thinking (`thinking.type: "enabled"` with `budget_tokens`) is not accepted on later models — use adaptive thinking steered by `effort`.

## Tokenizer note

Opus 4.7 and later (including all 5.x models) use a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic work / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
