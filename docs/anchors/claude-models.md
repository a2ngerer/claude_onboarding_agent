---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-07-01
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 4.x / 5.x is the current family as of `last_updated`. The Fable 5 tier sits above Opus as the highest-capability generally available model. Claude Sonnet 5 replaced Sonnet 4.6 as the Sonnet-tier model and became the Claude Code default on 2026-06-30 (v2.1.197). Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, Mythos-class reasoning, adaptive thinking |
| Opus   | `claude-opus-4-8`     | `opus`  | 1M      | 128k       | $5 / $25                  | Hard reasoning, deep code analysis, agentic workflows; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10 (intro, through 2026-08-31), then $3 / $15 | Balanced default — most coding and general tasks; defaults to high effort |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` is the same model as Fable 5 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-4-8`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date will stop working on that date; entries marked retired are already unavailable except on the noted cloud platform.

- `claude-opus-4-1` — retires 2026-08-05
- `claude-sonnet-4-6` — legacy, still available (superseded by Sonnet 5 as the default)
- `claude-opus-4-7` — legacy, still available
- `claude-opus-4-6` — legacy, still available
- `claude-opus-4-5` — legacy, still available
- `claude-sonnet-4-5` — legacy, still available
- `claude-opus-4` / `claude-sonnet-4` — **retired** (2026-06-15), except on Google Cloud (Bedrock also keeps Sonnet 4)
- `claude-haiku-3-5` — retired, except on Bedrock and Google Cloud
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

Fable 5, Mythos 5, Sonnet 5, and Opus 4.7+ use a new tokenizer that produces roughly 30% more tokens for the same text. Sonnet 4.6 and earlier models use the previous tokenizer. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default since v2.1.197):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-4-8`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
