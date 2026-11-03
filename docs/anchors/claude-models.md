---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-03
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

The Claude 5.5 generation (plus Fable 5.1) is current as of `last_updated`. The docs say to start with Opus 5.5 for most workloads and to move to Fable 5.1 for demanding reasoning, long-horizon agentic work, or when Opus 5.5 at higher effort still falls short on your evals. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias (`model:` field) | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|------------------------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M | 128k | $10 / $50   | high   | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M | 128k | $4 / $20    | medium | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M | 128k | $2 / $10    | high   | Best speed/intelligence balance |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M | 128k | from $0.10 / $0.50 | medium | High-volume, latency-sensitive: classification, extraction, routing |

Haiku 5.5 has two price tiers (the higher one is $0.50 / $2.50); check the pricing page for which applies. All current models use adaptive thinking. Batch API requests are 50% off; prompt-cache reads cost a fraction of base input price (e.g. $0.25/MTok on Fable 5.1).

Claude Mythos 5.1 has Fable 5.1 pricing but is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases resolve to the current recommended model for that tier and move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (`claude-opus-5-5`). For reproducibility across alias promotions, use the full ID directly.

## Legacy and retired

Legacy (still available, not recommended for new work): `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5`.

Retired — do not use: `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`. Older Claude 3.x, 2.x, and `claude-instant` models were already deprecated; do not use them either.

Claude Code has deprecated fast mode for Opus 4.8 (removal scheduled 2026-11-30); migrate to Opus 5.5.

Current retirement commitments: not sooner than 2027-09-01 (Fable 5.1), 2027-09-22 (Opus 5.5), 2027-09-28 (Sonnet 5.5), 2027-10-07 (Haiku 5.5). Check the model-deprecations page before pinning.

## Tokenizer note

Claude Opus 4.7 and later use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (Sonnet 4.6 and earlier). Factor this into cost estimates when migrating.

## Defaults

- **General starting point and agentic coding:** `claude-opus-5-5`
- **Everyday balanced work:** `claude-sonnet-5-5`
- **Hardest reasoning / long-horizon agents:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full model IDs in production; they are pinned. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Ultrathink runs at `xhigh` effort on Opus 5.5, Sonnet 5.5, Haiku 5.5, and Fable 5.1.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
