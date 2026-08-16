---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-16
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Opus 5 and Claude Sonnet 5 shipped 2026-08-14, superseding Opus 4.8 and Sonnet 4.6 as the current Opus/Sonnet tier. The Fable 5 tier still sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, Mythos-class reasoning, adaptive thinking |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` is the same model as Fable 5 but without dual-use safety measures. It is invitation-only (Project Glasswing) and not recommended for general use. Sonnet 5's $2/$10 pricing was introductory through 2026-08-31 but is now confirmed as the standard price; the previously scheduled increase to $3/$15 will not occur.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked "retired" only remain available on Bedrock/Google Cloud.

- `claude-opus-4-8` — legacy, still available (previous default Opus)
- `claude-opus-4-7` — legacy, still available
- `claude-opus-4-6` — legacy, still available
- `claude-opus-4-5-20251101` — legacy, still available
- `claude-sonnet-4-6` — legacy, still available (previous default Sonnet)
- `claude-sonnet-4-5-20250929` — legacy, still available
- `claude-opus-4-1` — retired, except on Bedrock and Google Cloud
- `claude-opus-4` — retired, except on Google Cloud
- `claude-sonnet-4` — retired, except on Bedrock and Google Cloud
- `claude-haiku-3-5` — retired, except on Bedrock and Google Cloud
- `claude-sonnet-4-0`, `claude-opus-4-0` — retired (past their 2026-06-15 retirement date)
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

Fable 5, Mythos 5, and Opus/Sonnet 4.7+ (including Opus 5 and Sonnet 5) use a new tokenizer that produces roughly 30% more tokens for the same text versus Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex enterprise work:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- On Opus 5 and Sonnet 5, the `effort` parameter defaults to `high` on the Claude API and Claude Code; set it explicitly for a different level.
