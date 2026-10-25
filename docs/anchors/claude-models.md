---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-25
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated` (Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5). Fable sits above Opus as the highest-capability tier. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Default for most workloads; long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance; default effort `high` |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / from $0.50   | High-volume, latency-sensitive tasks: classification, extraction, routing, subagents |

`claude-mythos-5-1` is the Fable-class model without dual-use safety measures. It is limited-availability and not recommended for general use.

Announced retirement commitments: Fable 5.1 not before 2027-09-01, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Short aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Use them when you want stability without memorizing a dated ID. Short aliases still move; for reproducibility across alias promotions, use the full ID.

## Legacy and retired

Do not use these in new code or configs.

- Legacy, still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`
- Past announced retirement dates: `claude-sonnet-4-0` and `claude-opus-4-0` (2026-06-15), `claude-opus-4-1` (2026-08-05)
- Older generations: `claude-sonnet-4-5`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Thinking and effort

Adaptive thinking is the supported mode. Manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is deprecated on Opus 4.6 / Sonnet 4.6 and not accepted on later models. Steer depth with the `effort` parameter instead. API default effort: Fable 5.1 `high`, Opus 5.5 `medium`, Sonnet 5.5 `high`, Haiku 5.5 `medium`.

## Tokenizer note

Models since Opus 4.7 use a tokenizer that yields roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads and agentic coding:** `claude-opus-5-5`
- **Fast everyday tasks:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full dateless IDs (`claude-opus-5-5`) for production stability. Short aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt-cache reads cost 10% of base input (5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.1); Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
