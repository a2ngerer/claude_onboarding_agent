---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-13
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Anthropic's guidance: start with Opus 5.5 for most workloads; use Fable 5.2 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable` | 1M      | 128k       | $8 / $40                  | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | high           | Balanced default — speed plus intelligence |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / from $0.50   | medium         | High-volume, latency-sensitive: classification, extraction, routing, subagent scans |

All current models use adaptive thinking (always on for Fable and Opus), accept text and image input, and have a June 2026 knowledge cutoff. Batch API is 50% off; cache reads cost 10% of base input (2.5% on Fable, 5% on Opus 5.5 and Sonnet 5.5).

`claude-mythos-5-2` is the Fable-class model without dual-use safety measures. Limited availability via Anthropic's Cyber Verification Program; not for general use.

## Aliases

The `model:` field in Claude Code accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases resolve to the current recommended model for that tier and move when Anthropic promotes a new default (e.g. saved Fable 5.1 selections migrated to `fable` in Claude Code 2.1.321).

## ID pinning behavior

Every current Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Use them for stability; use aliases only if you want to follow promotions.

## Deprecated / retiring

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` — retired on the Claude API (may remain on some cloud partners)
- Older but still available: `claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001`
- Claude 3.x and earlier (`claude-3-*`, `claude-2.*`, `claude-instant-1.2`) — long deprecated

Current retirement commitments (not sooner than): Fable 5.2 — 2027-11-09, Opus 5.5 — 2027-09-22, Sonnet 5.5 — 2027-09-28, Haiku 5.5 — 2027-10-07.

## Tokenizer note

Opus 4.7 and later use a newer tokenizer that produces roughly 30% more tokens for the same text (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from pre-4.7 models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5` (Claude Code's `sonnet` alias)
- **Most workloads / long-running agentic coding:** `claude-opus-5-5`
- **Deep reasoning, maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases move when defaults are promoted.
- Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models; use adaptive thinking steered by `effort`.
- Unknown model IDs are assumed to have a 1M window in Claude Code 2.1.323+; set `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` to keep 200K.
- When migrating between models, re-run your eval suite; prompts tuned for one family may need light adjustment.
