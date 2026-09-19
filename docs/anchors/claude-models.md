---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-19
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Fable 5.1 / Opus 5 / Sonnet 5 / Haiku 4.5 is the current lineup as of `last_updated`. Fable 5.1 sits above Opus 5 as the highest-capability generally available model, with adaptive thinking always on. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                     | Alias               | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-------------------------------|----------------------|---------|------------|----------------------------|-------------------|
| Fable  | `claude-fable-5-1`           | `claude-fable-5-1`  | 1M      | 128k       | $10 / $50                  | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5`              | `claude-opus-5`     | 1M      | 128k       | $5 / $25                   | Complex agentic coding, enterprise work |
| Sonnet | `claude-sonnet-5`            | `claude-sonnet-5`   | 1M      | 128k       | $2 / $10                   | Balanced default — best speed/intelligence combo |
| Haiku  | `claude-haiku-4-5-20251001`  | `claude-haiku-4-5`  | 200k    | 64k        | $1 / $5                    | Fastest, near-frontier intelligence; subagent scans |

`claude-mythos-5` and `claude-mythos-5-1` are the same models as Fable 5 / Fable 5.1 without dual-use safety measures. Both are invitation-only (limited availability) and not recommended for general use.

## Aliases

The `model:` field accepts short names (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). For the 4.6+ generation, the dateless model ID *is* the alias — it is a pinned snapshot, not a moving pointer. Pre-4.6 aliases (e.g. on legacy Opus/Sonnet tiers) still resolve to a dated ID underneath.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. There is no "moving alias" for current-generation tiers — pick the dateless ID for stability, or the dated Haiku ID (`claude-haiku-4-5-20251001`) for full reproducibility.

## Legacy / deprecated

Still available but superseded by the table above:

- `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`

Retired (except on Bedrock/Google Cloud, which set their own lifecycle dates) — do not use in new code:

- `claude-opus-4-1`, `claude-opus-4`, `claude-sonnet-4`, `claude-haiku-3-5`
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Retirement is now a forward commitment ("not sooner than \<date\>") rather than a fixed announced date — check the model-deprecations page before assuming a currently-available model is safe long-term.

## Tokenizer note

Claude 4.7 and later models use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / hard enterprise work:** `claude-opus-5`
- **Maximum capability, long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use the dateless ID (`claude-opus-5`) for production stability; it's a pinned snapshot. Aliases (`opus`, `sonnet`, etc.) still move when Anthropic promotes a new default tier.
- Sonnet 5's $2/$10 launch pricing is now the standard price — the previously scheduled increase to $3/$15 was cancelled.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
