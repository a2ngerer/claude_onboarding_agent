---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-24
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 4.x / 5.x is the current family as of `last_updated`. Claude Fable 5.1 sits above Opus as the highest-capability generally available model; Claude Opus 5.5 is Anthropic's recommended starting point for most workloads and is now the default model on Pro/Team Standard plans (replacing Sonnet). Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------|---------|------------|----------------------------|-------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                  | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`           | `opus`  | 1M      | 128k       | $4 / $20                   | Long-running agentic coding and knowledge work; recommended starting point |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                   | Best combination of speed and intelligence — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                    | Fastest, near-frontier intelligence; cheap subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It ships as part of Project Glasswing, invitation-only, and is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude API model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Legacy (still available, prefer the current lineup for new work)

`claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

## Retired

Retired from the Claude API (may still be available on Bedrock/Google Cloud): `claude-opus-4-1`, `claude-opus-4-0` (aka `claude-opus-4`), `claude-sonnet-4-0`, `claude-haiku-3-5`, and all Claude 3.x IDs (`claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`). Do not use these in new code or configs.

## Retirement commitments (current lineup)

Anthropic's not-sooner-than commitment for Anthropic-operated platforms:

- Fable 5.1 — 2027-09-01
- Opus 5.5 — 2027-09-22
- Sonnet 5 — 2027-06-30
- Haiku 4.5 — 2026-10-15

## Tokenizer note

Models from Claude Opus 4.7 onward, including the whole 5.x family, use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier models. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / most workloads:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Sonnet 5's `$2/$10` per-MTok pricing was introductory through 2026-08-31; it is now the standard, permanent price.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
