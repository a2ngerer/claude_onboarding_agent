---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-26
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current generation. Claude Opus 5.5 is Anthropic's general recommendation for most workloads; Claude Fable 5.1 (and the invitation-only Claude Mythos 5.1) sit above Opus for the hardest reasoning and longest-horizon agentic work. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`           | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; Anthropic's default recommendation for most workloads |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — balanced default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                   | Fastest model with near-frontier intelligence; high-volume tasks and subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It ships under Project Glasswing, invitation-only, and is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). For the current generation, an alias resolves to the same pinned snapshot as its dateless ID — the only exception is Haiku, whose alias (`claude-haiku-4-5`) drops the release date the ID carries (`claude-haiku-4-5-20251001`).

## ID pinning behavior

Since the 4.6 generation, every Claude model ID — including dateless IDs like `claude-opus-5-5` — is a pinned snapshot, not a moving pointer. Use the dateless or dated ID directly for guaranteed reproducibility across releases.

## Retirement commitments

Anthropic commits not to retire a current model sooner than:

- Fable 5.1 — 2027-09-01
- Opus 5.5 — 2027-09-22
- Sonnet 5 — 2027-06-30
- Haiku 4.5 — **2026-10-15** (nearest upcoming date — plan Haiku-dependent subagents ahead of this)

Legacy models still available but no longer recommended for new work: Fable 5, Opus 5, Opus 4.8, Opus 4.7, Opus 4.6, Opus 4.5, Sonnet 4.6, Sonnet 4.5.

Retired on the Claude API (may still be available on Bedrock/Google Cloud): Opus 4.1, Opus 4, Sonnet 4, Haiku 3.5, and all Claude 3.x / 2.x / Instant IDs.

## Tokenizer note

Claude Opus 4.7 and later, and every Claude 5.x model, use a newer tokenizer that produces roughly 30% more tokens for the same text than Claude Sonnet 4.6 and earlier. Factor this into cost and context-budget estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding (balanced speed/cost):** `claude-sonnet-5`
- **Hard reasoning, deep code analysis, most workloads:** `claude-opus-5-5`
- **Maximum capability, long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs for production stability; they are pinned snapshots since the 4.6 generation.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Prompt-cache reads are cheaper than the standard 10% multiplier on some tiers: 2.5% on Fable/Mythos 5.1, 5% on Opus 5.5.
