---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-09
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Fable 5.1 / Opus 5 / Sonnet 5 / Haiku 4.5 is the current lineup as of `last_updated`. Fable 5.1 sits above Opus 5 as the highest-capability generally available model — start with Opus 5 for most workloads, and move to Fable 5.1 for demanding reasoning or long-horizon agentic work. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`      | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fastest model with near-frontier intelligence; subagent scans |

`claude-mythos-5-1` and `claude-mythos-5` are the same models as Fable 5.1 / Fable 5 but without dual-use safety measures. Both are invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5`, `claude-sonnet-5`). Aliases still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Legacy / deprecated / retiring

Legacy models remain available at their original pricing: `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

Retired except on Bedrock and Google Cloud: `claude-opus-4-1`, `claude-opus-4-0` (a.k.a. `claude-opus-4`), `claude-sonnet-4-0`, `claude-haiku-3-5`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`. Do not use these in new code or configs.

Retirement commitments for current-generation models (not sooner than): Fable 5.1 2027-09-01, Opus 5 2027-07-24, Sonnet 5 2027-06-30, Haiku 4.5 2026-10-15. Amazon Bedrock and Google Cloud set their own retirement dates.

## Tokenizer note

Claude 4.7 and later models — including the whole Sonnet/Opus/Fable 5.x line — use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt cache reads are priced at 0.1x base input on most models, but only 0.025x on Fable 5.1 and Mythos 5.1 — factor this into caching cost estimates.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
