---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-27
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current generation as of `last_updated` (Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5). Fable sits above Opus as the highest-capability generally available tier. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; recommended starting point for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — everyday coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

`claude-mythos-5-2` is the Fable 5.2 counterpart without dual-use safety measures. It is limited-availability (verified organizations only) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier and move when Anthropic promotes a new default. On some cloud platforms aliases lag: e.g. on Bedrock `sonnet` may still resolve to Sonnet 4.5 — check the platform's model table.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Aliases are the only moving pointers; use the full ID when you need reproducibility across alias promotions.

## Thinking and effort

Current models use adaptive thinking (steered by `effort`); manual `thinking.type: "enabled"` with `budget_tokens` is not accepted on later models. Default effort on the API: `high` for Fable and Sonnet, `medium` for Opus and Haiku — set it explicitly to override.

## Previous generation (still available)

`claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6` (1M context); `claude-opus-4-5`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001` (200k context). Prefer the 5.5 IDs for new work.

## Retired / deprecated

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` — retired on the Claude API and Foundry (may remain on Bedrock / Google Cloud)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Anthropic's earliest-retirement commitments for the 5.5 models run from Sept 2027 (Opus 5.5) to Nov 2027 (Fable 5.2).

## Tokenizer note

Opus 4.7 and later use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens is about 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Prompt-cache reads cost 10% of base input (5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.2); Batch API is 50% off.
