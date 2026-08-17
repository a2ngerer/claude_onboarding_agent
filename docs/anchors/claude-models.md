---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-17
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Claude Opus 5 went GA on 2026-07-24 and is now the default Opus model, replacing Opus 4.8 as the recommended tier for complex agentic coding and enterprise work. Fable 5 remains the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing; it is part of Project Glasswing, invitation-only, and not recommended for general use. `claude-mythos-preview` is a further invitation-only research variant.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy (still available)

- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy Opus snapshots
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy Sonnet snapshots

## Retired

Do not use these IDs in new code or configs. Most are fully retired; a few remain only on Bedrock/Google Cloud.

- `claude-opus-4-1`, `claude-opus-4` — retired except on Bedrock/Google Cloud
- `claude-sonnet-4` — retired except on Bedrock/Google Cloud
- `claude-haiku-3-5` — retired except on Bedrock/Google Cloud
- `claude-sonnet-4-0`, `claude-opus-4-0` — retired
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Fable 5, Sonnet 5, Mythos 5, and Opus 4.7+ use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / enterprise:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- `effort` defaults to `high` on the Claude API and Claude Code for Opus 5, Sonnet 5, and Opus 4.8+; set it explicitly for a different level.
- Fast mode (research preview) offers premium-priced low-latency output for Opus 5 / Opus 4.8, billed at $10/$50 per MTok — double base Opus 5 rates.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
