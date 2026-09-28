---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-28
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. The Fable 5.1 tier sits above Opus as the highest-capability generally available model; Opus 5.5 is the recommended default for most workloads. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Default effort | Retires (Anthropic platforms) |
|--------|------------------------------|---------|---------|------------|----------------------------|-----------------|--------------------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                  | high            | not sooner than 2027-09-01     |
| Opus   | `claude-opus-5-5`           | `opus`  | 1M      | 128k       | $4 / $20                   | medium          | not sooner than 2027-09-22     |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                   | high            | not sooner than 2027-06-30     |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                    | n/a             | not sooner than 2026-10-15     |

Cache-read pricing is 0.1x base input on Sonnet/Haiku, 0.05x on Opus 5.5 ($0.20/MTok), and 0.025x on Fable 5.1 ($0.25/MTok). "Retires" is Anthropic's commitment floor for its own platforms (Claude API, Claude Platform on AWS, Microsoft Foundry), not a scheduled date — Bedrock and Google Cloud set their own lifecycle.

`claude-mythos-5-1` and `claude-mythos-5` are the same models as Fable 5.1 / Fable 5 without dual-use safety measures (Project Glasswing). Invitation-only, not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID — including dateless IDs from the 4.6 generation on — is a pinned snapshot, not a moving pointer. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the ID directly.

## Legacy (still available, not recommended for new work)

`claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

## Retired

Retired on Anthropic-operated platforms, may still be available on Bedrock/Google Cloud under their own lifecycle: `claude-opus-4-1`, `claude-opus-4-0` / `claude-opus-4`, `claude-sonnet-4-0`, `claude-haiku-3-5`.

Fully deprecated everywhere — do not use in new code or configs:

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

Claude 4.7 and later models (including Fable 5.1, Mythos 5.1, and Opus 5.5) use a newer tokenizer that produces roughly 30% more tokens for the same text than Claude Sonnet 4.6 and earlier. Factor this into cost and context-budget estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5` — best balance of speed and cost. Claude Code's Pro and Team Standard plans now default interactive sessions to Opus rather than Sonnet.
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability / long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
