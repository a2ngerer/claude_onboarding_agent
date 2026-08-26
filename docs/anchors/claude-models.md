---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-26
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Opus 5, Sonnet 5, Fable 5, and Haiku 4.5 are the current lineup as of `last_updated`. Opus 5 is the default pick for complex agentic coding and enterprise work; Fable 5 remains the highest-capability generally available model. Default to the IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents, adaptive thinking |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fastest, near-frontier intelligence; high-volume tasks and subagents |

`claude-mythos-5` is the same model as Fable 5 but without dual-use safety measures. It has limited availability and is not recommended for general use.

Sonnet 5's $2/$10 pricing was introductory through 2026-08-31 and is now the standard price — the previously scheduled increase to $3/$15 will not occur.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

**Legacy, still available** (superseded by the 5-generation defaults above — no retirement date announced yet): `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

**Fully retired** on the Claude API (Bedrock and Google Cloud set their own, later dates): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-haiku-3-5`, and all Claude 3.x / 2.x IDs (`claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`). Do not use any of these in new code or configs.

**Retirement commitments** for current models (not sooner than): Fable 5 — 2027-06-09; Opus 5 — 2027-07-24; Sonnet 5 — 2027-06-30; Haiku 4.5 — 2026-10-15.

## Tokenizer note

Claude 4.7 and later models (including the current Fable 5 / Opus 5 / Sonnet 5 generation) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex coding:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- **Fast mode** (research preview) gives significantly faster output at premium pricing ($10/$50 per MTok); supported only on Opus 5 and Opus 4.8, first-party Claude API only.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
