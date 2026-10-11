---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-11
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability generally available tier. Start with Opus 5.5 for most workloads; use Fable 5.1 for demanding reasoning and long-horizon agentic work. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort medium |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence for most coding tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | Classification, extraction, routing, high-volume subagents |

`claude-mythos-5-1` is the Fable 5.1 counterpart without dual-use safety measures. It is invitation-only and not recommended for general use.

Prompt cache reads cost 10% of base input price (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1). Batch API requests are 50% off.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every current model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. Use them when you want stability. Aliases still move; for reproducibility across alias promotions, use the ID directly.

## Retirement

Anthropic commits to keeping current models available until at least: Fable 5.1 — 2027-09-01, Opus 5.5 — 2027-09-22, Sonnet 5.5 — 2027-09-28, Haiku 5.5 — 2027-10-07.

## Legacy (still available) and deprecated

Do not use these IDs in new code or configs.

- Legacy, still available: `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`
- Past their announced retirement dates (verify on the deprecations page): `claude-sonnet-4-0`, `claude-opus-4-0` (2026-06-15), `claude-opus-4-1` (2026-08-05)
- Older generations: `claude-sonnet-4-5`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Models from Opus 4.7 onward share a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens is about 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / most workloads:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use the dateless IDs for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Thinking is adaptive on current models; steer it with the `effort` parameter rather than manual `budget_tokens`.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
