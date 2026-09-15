---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-15
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.1 sits above Opus 5 as the highest-capability generally available model, for demanding reasoning and long-horizon agentic work; Mythos 5.1 is its invitation-only counterpart without dual-use safety measures. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5`             | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                   | Fastest model with near-frontier intelligence; high-volume tasks and subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5-1`) are pinned snapshots, not moving pointers — this includes every current-generation ID. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Fast mode

Claude Opus 5 and Opus 4.8 support fast mode (research preview): significantly faster output at premium pricing ($10 / $50 per MTok, applied across the full context window). Claude API (first-party) only — not available on Claude Platform on AWS or partner-operated cloud platforms. Not available on Opus 4.7 or earlier.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- **Retired, except on Bedrock and Google Cloud:** `claude-opus-4-1`, `claude-opus-4`, `claude-sonnet-4`, `claude-haiku-3-5`
- **Legacy, still available at standard pricing:** `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Retirement commitments (Anthropic-operated platforms)

- Haiku 4.5: not sooner than 2026-10-15
- Sonnet 5: not sooner than 2027-06-30
- Opus 5: not sooner than 2027-07-24
- Fable 5.1: not sooner than 2027-09-01

Bedrock and Google Cloud set their own retirement dates for the same models.

## Tokenizer note

Claude Opus 4.7+ and the Mythos/Fable 5.x line use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
