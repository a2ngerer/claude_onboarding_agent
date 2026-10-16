---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-16
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5. The Fable tier sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason. Anthropic's guidance: start with Opus 5.5 for most workloads; use Fable 5.1 when evals on Opus 5.5 at higher effort still fall short.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence for most coding tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | $0.10 / $0.50 (≤100k prompt); $0.50 / $2.50 above | High-volume, latency-sensitive work: classification, extraction, routing, subagent scans |

All four use adaptive thinking. `claude-mythos-5-1` is the Fable-class model without dual-use safety measures; it is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. The `fable` and `best` aliases fall back to the previous Fable model when the newest is not available (Claude Code 2.1.301).

## ID pinning behavior

Every model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. Aliases are what move. For reproducibility, use the model ID directly.

## Legacy (still available)

`claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101` (not sooner than 2026-11-24), `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` (not sooner than 2026-10-15).

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — deprecated; **retires 2026-11-30** (replacement `claude-sonnet-5-5`)
- `claude-opus-4-1-20250805` — retired 2026-08-05
- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — retired 2026-06-15
- `claude-3-haiku-20240307`, `claude-3-5-haiku-20241022`, `claude-3-7-sonnet-20250219` — retired
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022` — retired
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2` — retired
- `claude-mythos-preview` — deprecated

API parameters: `temperature`, `top_p`, `top_k` return a 400 when set to non-default values on Claude 4.7 and later; omit them. Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models; use adaptive thinking with `effort`.

## Tokenizer note

Claude Opus 4.7 and later use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Most workloads / agentic planning (Anthropic's starting point):** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Prompt cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1); Batch API is 50% off.
- Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted; use full IDs for production stability.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
