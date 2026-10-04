---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-04
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, plus Haiku 4.5. Fable sits above Opus as the highest-capability generally available tier. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`     | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; start here for most workloads |
| Sonnet | `claude-sonnet-5-5`   | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence for most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

Claude Mythos 5.1 is the Fable-class model without dual-use safety measures. It is limited-availability (Project Glasswing, invitation-only) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them for stability without memorizing a full dated ID. Short aliases (`opus`, `sonnet`) still move; use the model ID if you want reproducibility across alias promotions.

## Pricing notes

- Prompt cache reads cost 10% of base input, except 2.5% on Fable 5.1 / Mythos 5.1 and 5% on Opus 5.5.
- Batch API is 50% off; the full 1M context is billed at standard per-token rates.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date will stop working on that date.

- `claude-haiku-4-5-20251001` — still current, but retirement is "not sooner than 2026-10-15"; watch for a successor announcement
- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — retired on the Claude API
- Legacy, still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`
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

Claude 4.7 and later models use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / long-running agentic work:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use model IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Default effort differs by model (Opus 5.5 `medium`; Fable 5.1 and Sonnet 5.5 `high`); set effort explicitly if you need a different level.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
