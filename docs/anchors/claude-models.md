---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-13
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated` (Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5). Start with Opus 5.5 for most workloads; use Fable 5.1 for demanding reasoning and long-horizon agentic work. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k); $0.50 / $2.50 (>100k) | High-volume, latency-sensitive work: classification, extraction, routing, subagents |

Prompt-cache reads cost 10% of base input (2.5% on Fable 5.1 and Mythos 5.1, 5% on Opus 5.5 and Sonnet 5.5). Batch API requests are 50% off. Mythos models are limited-availability variants without dual-use safety measures; not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases resolve to the current recommended model for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them for stability without memorizing a dated ID. Only the short aliases move; use the full ID for reproducibility across alias promotions.

## Legacy (still available)

Usable but not recommended for new work: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`.

Current-generation retirement is not sooner than 2027-09-01 (Fable 5.1), 2027-09-22 (Opus 5.5), 2027-09-28 (Sonnet 5.5), and 2027-10-07 (Haiku 5.5).

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — retired on the Claude API (may linger on Bedrock / Google Cloud)
- `claude-sonnet-4-5` — deprecated
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

Claude 4.7 and later models (including the whole 5.x family) use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Hard reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Adaptive thinking replaces manual `thinking.type: "enabled"` + `budget_tokens` on 5.x models; steer depth with the `effort` parameter instead.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
