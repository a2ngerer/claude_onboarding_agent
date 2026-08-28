---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-28
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5-series (Fable 5, Opus 5, Sonnet 5) plus Haiku 4.5 is the current lineup as of `last_updated`. Opus 5 and Sonnet 5 have superseded Opus 4.8 and Sonnet 4.6 as the recommended defaults for their tiers. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` is the same model as Fable 5 but without dual-use safety measures. Limited availability, invitation-only, not recommended for general use.

Sonnet 5's $2/$10 pricing was introductory through 2026-08-31 and is now the standard price — the previously scheduled increase to $3/$15 will not occur.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID, including the dateless IDs used from the 4.6 generation on, is a pinned snapshot, not a moving pointer. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Retired (except on Bedrock and Google Cloud, which set their own dates)

- `claude-opus-4-1` — retired 2026-08-05
- `claude-opus-4-0` (Opus 4) — retired 2026-06-15
- `claude-sonnet-4-0` (Sonnet 4) — retired 2026-06-15
- `claude-haiku-3-5` — retired

## Legacy (still available, not recommended for new work)

- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`
- `claude-sonnet-4-6`, `claude-sonnet-4-5`

## Unsupported — do not use in new code or configs

- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models, plus all 5-series models (Fable 5, Opus 5, Sonnet 5) and Claude Mythos, use a newer tokenizer that produces roughly 30% more tokens for the same text. Claude Sonnet 4.6 and earlier use the previous tokenizer. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
