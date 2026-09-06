---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-06
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Claude Fable 5.1 sits above Opus as the highest-capability generally available model, followed by Opus 5, Sonnet 5, and Haiku 4.5. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias         | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`           | `fable`       | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5`               | `opus`        | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`             | `sonnet`      | 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001`  | `haiku`       | 200k    | 64k        | $1 / $5                   | Fastest model, near-frontier intelligence; fast/cheap subagents |

`claude-mythos-5-1` is the same generation as Fable 5.1 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude API model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on — they do not move. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy (still available)

- `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`

## Retired (except on Bedrock/Google Cloud, which set their own dates)

- `claude-opus-4-1`, `claude-opus-4`, `claude-sonnet-4`, `claude-haiku-3-5`
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Retirement commitments (current generation)

Anthropic-operated platforms commit not to retire a current-generation model sooner than: Fable 5.1 — 2027-09-01; Opus 5 — 2027-07-24; Sonnet 5 — 2027-06-30; Haiku 4.5 — 2026-10-15.

## Tokenizer note

Claude 4.7 and later models (including Fable 5.1, Mythos, Opus 5) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex coding:** `claude-opus-5`
- **Maximum capability / long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; every Claude API ID is a pinned snapshot since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 5's $2/$10 launch pricing is now the standard rate — a previously planned increase to $3/$15 will not occur.
