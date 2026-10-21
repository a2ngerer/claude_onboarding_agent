---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-21
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. The Fable tier sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

All current models share a 1M-token context window and 128k max output, support adaptive thinking, and have a June 2026 knowledge cutoff.

| Tier   | Model ID            | Alias    | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work; start here if Opus 5.5 at higher effort still falls short |
| Opus   | `claude-opus-5-5`   | `opus`   | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; the general starting point for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | $2 / $10                  | high           | Best speed/intelligence balance — everyday coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | $0.10 / $0.50 (prompts ≤100k tokens; $0.50 / $2.50 above) | medium | Fast, cheap, high-volume tasks: classification, extraction, routing, subagent scans |

`claude-mythos-5-1` is priced like Fable 5.1 but without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. Every Claude model ID, including dateless ones, is a pinned snapshot.

## Pricing notes

Batch API requests are 50% off. Prompt cache reads cost 10% of base input price (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1).

## Legacy and deprecated

Do not use these IDs in new code or configs.

- Still available (legacy): `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`
- `claude-opus-4-5-20251101` — not sooner than 2026-11-24
- `claude-sonnet-4-5-20250929` — **deprecated; retires 2026-11-30** (replace with `claude-sonnet-5-5`)
- `claude-haiku-4-5-20251001` — not sooner than 2026-10-15 (replace with `claude-haiku-5-5`)
- Retired (requests fail): `claude-opus-4-1-20250805`, `claude-opus-4-20250514`, `claude-sonnet-4-20250514`, `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`, `claude-3-opus-20240229`, `claude-3-5-sonnet-*`, `claude-3-sonnet-20240229`, `claude-2.x`, `claude-instant-*`

## Parameter and tokenizer notes

- Since Claude 4.7, `temperature`, `top_p`, and `top_k` return a 400 error when set to a non-default value. Omit them and steer with prompting.
- Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on newer models; use adaptive thinking and the `effort` parameter.
- The tokenizer introduced with Opus 4.7 produces roughly 30% more tokens than earlier models for the same text. Factor this into cost estimates when migrating.

## Defaults

- **Starting point for most workloads:** `claude-opus-5-5`
- **Everyday tasks and fast agentic coding:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
