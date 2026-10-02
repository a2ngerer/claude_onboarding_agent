---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-02
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`, plus Haiku 4.5. Fable 5.1 sits above Opus as the highest-capability generally available model. Anthropic's docs recommend starting with Opus 5.5 for most API workloads; Claude Code defaults to Sonnet 5.5. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`           | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5`         | `sonnet`| 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` is the Fable 5.1 tier without dual-use safety measures. It is invitation-only (Project Glasswing) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, every Claude model ID, including dateless ones (e.g. `claude-opus-5-5`), is a pinned snapshot, not a moving pointer. Use them for stability without memorizing a dated ID. Short aliases (`opus`, `sonnet`, …) still move on promotion; use the full ID for reproducibility.

## Legacy and retired

Prefer the current models above in new code or configs.

- Still available (legacy): `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001` — current, but retirement is not sooner than 2026-10-15; check the deprecations page before pinning
- Retired on the Claude API (may remain on Bedrock / Google Cloud): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-3-5-haiku-20241022`
- Older generations — do not use:
  - `claude-3-opus-20240229`
  - `claude-3-sonnet-20240229`
  - `claude-3-haiku-20240307`
  - `claude-3-5-sonnet-20240620`
  - `claude-3-5-sonnet-20241022`
  - `claude-2.1`
  - `claude-2.0`
  - `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (including Fable 5.x, Mythos 5.x, Opus 5.x, Sonnet 5.x) use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5-5`
- **Long-running agentic coding / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt-cache reads cost 10% of base input (5% on Opus 5.5, 2.5% on Fable 5.1); Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
