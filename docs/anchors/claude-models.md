---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-08
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability model. Anthropic recommends starting with Opus 5.5 for most workloads and moving to Fable 5.1 for demanding reasoning and long-horizon agentic work. Default to the IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; start here |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50 (prompts up to 100k; $0.50 / $2.50 above) | medium | Classification, extraction, routing, cheap subagents |

All current models use adaptive thinking (always on for Fable and Opus) steered by the `effort` parameter. Every model ID is a pinned snapshot. Retirement commitments: Fable 5.1 not before 2027-09-01, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier and move when Anthropic promotes a new default. On Bedrock, Vertex, and Foundry the aliases fall back to an older model when the newest is unavailable.

## ID pinning behavior

Undated model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them for stability; aliases still move.

## Legacy / deprecated

Still available but not recommended for new work: `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-haiku-4-5`.

- **Fast mode for Opus 4.8** is deprecated and is removed on **2026-11-30**; requests then error with no fallback. Migrate to Opus 5.5.
- Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models; use adaptive thinking.
- Retired or retiring earlier IDs (do not use): `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1`, `claude-3-*`, `claude-2.*`, `claude-instant-1.2`.

`claude-mythos-5-1` has limited availability and is not recommended for general use.

## Tokenizer note

Models since Opus 4.7 use a tokenizer that yields roughly 30% more tokens than older models for the same text (1M tokens is about 555k words). Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5` (or `claude-opus-5-5` for long-running work)
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use undated IDs for production stability. Aliases move when defaults are promoted.
- Prompt cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1); the Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
