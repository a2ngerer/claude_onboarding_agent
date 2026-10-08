---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-08
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability generally available model. Start with Opus 5.5 for most workloads; move to Fable 5.1 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — speed and intelligence for most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | $0.10 / $0.50 (prompts >100k: $0.50 / $2.50) | Fast, cheap, high-volume tasks: classification, extraction, routing, subagents |

All four use adaptive thinking and have a June 2026 knowledge cutoff. `claude-mythos-5-1` is the Fable-class model without dual-use safety measures; it is limited-availability (verified organizations only) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Use them for stability without memorizing a dated ID. Claude Code aliases still move; for reproducibility across alias promotions, use the full ID directly.

## Legacy and retired

Do not use these IDs in new code or configs.

- Legacy (still available): `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001`
- Retired on the Claude API (may persist on Bedrock / Google Cloud): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-3-5-haiku-20241022`
- Older and long retired:
  - `claude-3-opus-20240229`
  - `claude-3-sonnet-20240229`
  - `claude-3-haiku-20240307`
  - `claude-3-5-sonnet-20240620`
  - `claude-3-5-sonnet-20241022`
  - `claude-2.1`
  - `claude-2.0`
  - `claude-instant-1.2`

Current models are committed to stay available on Anthropic-operated platforms until at least September 2027 (Fable 5.1: 2027-09-01; Opus 5.5: 2027-09-22; Sonnet 5.5: 2027-09-28; Haiku 5.5: 2027-10-07).

## Tokenizer note

Claude 4.7 and later models use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Pricing notes

- Batch API: 50% off input and output. Prompt cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5; 2.5% on Fable 5.1).
- Haiku 5.5 is the only current model with length-tiered pricing; the other 4.6+ models include the full 1M context at standard rates.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Adaptive thinking is steered by `effort`; manual `thinking.type: "enabled"` with `budget_tokens` is not accepted on later models.
