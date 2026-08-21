---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-21
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 4.x / 5.x is the current family as of `last_updated`. Claude Opus 5 and Claude Sonnet 5 are now the current-generation Opus and Sonnet models, replacing Opus 4.8 and Sonnet 4.6 as the recommended defaults for their tiers. The Fable 5 tier still sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, Mythos-class reasoning, adaptive thinking |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Hard reasoning, deep code analysis, agentic workflows; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks; defaults to high effort |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

Sonnet 5's $2/$10 pricing launched as an introductory rate through 2026-08-31; Anthropic has since confirmed it as the standard, permanent price (the planned increase to $3/$15 will not happen).

`claude-mythos-5` is the same model as Fable 5 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries below marked "retired" have already stopped working on the Claude API (Bedrock/Google Cloud may retain them longer, as noted).

- `claude-sonnet-4-0` — **retired 2026-06-15** (except Bedrock/Google Cloud)
- `claude-opus-4-0` — **retired 2026-06-15** (except Google Cloud)
- `claude-opus-4-1` — **retired 2026-08-05** (except Bedrock/Google Cloud)
- `claude-opus-4-8` — legacy, still available
- `claude-opus-4-7` — legacy, still available
- `claude-opus-4-6` — legacy, still available
- `claude-opus-4-5` — legacy, still available
- `claude-sonnet-4-6` — legacy, still available
- `claude-sonnet-4-5` — legacy, still available
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022` — retired, except Bedrock/Google Cloud
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Fable 5, Mythos 5, Opus 4.7+ (including Opus 5), and Sonnet 5 use a new tokenizer that produces roughly 30% more tokens for the same text. Sonnet 4.6 and earlier use the previous tokenizer. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- On Opus 5 and Sonnet 5, the `effort` parameter now defaults to `high` on the Claude API and Claude Code (previously high-effort-by-default was Opus-only); set it explicitly for other levels.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
