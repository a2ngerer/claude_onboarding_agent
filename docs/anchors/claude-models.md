---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-15
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Anthropic's guidance is to start with Opus 5.5 for most workloads and move to Fable 5.1 for demanding reasoning and long-horizon agentic work. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | Maximum capability, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | Fast, cheap, high-volume tasks, classification, routing, subagents |

Haiku 5.5 pricing is $0.10 / $0.50 for prompts up to 100k tokens and $0.50 / $2.50 above that. Prompt-cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1). Batch API requests are 50% off.

`claude-mythos-5-1` is the Fable-class model without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every current Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Aliases in Claude Code still move; if you want reproducibility across alias promotions, use the full model ID.

## Legacy and deprecated

Still available (legacy): `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`.

Do not use these in new code or configs:

- `claude-sonnet-4-5-20250929` — deprecated, **retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-opus-4-1-20250805` — retired 2026-08-05
- `claude-sonnet-4-20250514`, `claude-opus-4-20250514` — retired 2026-06-15
- `claude-3-haiku-20240307` — retired 2026-04-20
- `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022` — retired 2026-02-19
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022` — retired 2025-10-28
- `claude-3-opus-20240229` — retired 2026-01-05
- `claude-3-sonnet-20240229`, `claude-2.1`, `claude-2.0` — retired 2025-07-21
- `claude-instant-1.2` and earlier — retired 2024-11-06

## Tokenizer and parameter notes

- Opus 4.7 and later (including all 5.x models) use a tokenizer that produces roughly 30% more tokens for the same text than earlier models. Factor this into cost estimates when migrating.
- On Claude 4.7 and later, `temperature`, `top_p`, and `top_k` return a 400 error when set to a non-default value. Omit them and steer behavior through prompting.
- Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models; use adaptive thinking steered by `effort`.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / long-running agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full model IDs for production stability; use aliases (`opus`, `sonnet`, etc.) when you want to follow promoted defaults.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
