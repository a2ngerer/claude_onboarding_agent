---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-26
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Fable sits above Opus as the highest-capability generally available tier. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks: classification, extraction, routing, subagents |

Claude Mythos 5.1 is priced like Fable 5.1 but is limited-availability and not recommended for general use.

Anthropic's retirement commitments: Fable 5.1 not before 2027-09-01, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier and move when Anthropic promotes a new default. The `fable` alias retries once on the previous Fable model if the newest one is not available to your organization.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Aliases still move; for reproducibility across alias promotions, use the full ID directly.

## Legacy (still available)

Prefer the current family for new work. Still available, but not recommended for new configs:

- `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`
- `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001`

## Retired / deprecated

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0` — retired 2026-06-15
- `claude-opus-4-1` — retired 2026-08-05
- `claude-sonnet-4-5` — no longer in the current or legacy lineup; migrate to Sonnet 5.5
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Thinking and effort

Current models use adaptive thinking, steered by the `effort` parameter (defaults: Fable `high`, Opus `medium`, Sonnet `high`, Haiku `medium`). Manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is deprecated on Opus 4.6 and Sonnet 4.6 and rejected on later models.

## Tokenizer note

Opus 4.7 and later models use a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens is about 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5` (or `claude-opus-5-5` for long-running agentic work)
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full dateless IDs (`claude-opus-5-5`) for production stability. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Batch API requests are 50% off; prompt-cache reads cost a fraction of base input price (see the pricing page).
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
