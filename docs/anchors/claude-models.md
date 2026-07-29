---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-07-29
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Fable 5 / Opus 5 / Sonnet 5 / Haiku 4.5 is the current family as of `last_updated`. Fable 5 is Anthropic's most capable widely released model. Opus 5 is recommended for complex agentic coding and enterprise work; Sonnet 5 is the best balance of speed and intelligence and is now the Claude Code default. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding, enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10 (introductory through 2026-08-31, then $3 / $15) | Balanced default — most coding and general tasks; defaults to high effort |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing; limited availability via Project Glasswing. `claude-mythos-preview` is a separate invitation-only model for defensive cybersecurity workflows, also under Project Glasswing.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date will stop working on that date.

- `claude-opus-4-1-20250805` — **retires 2026-08-05 (imminent)**
- `claude-opus-4-0` — retired 2026-06-15 (still available on Google Cloud only)
- `claude-sonnet-4-0` — retired 2026-06-15 (still available on Bedrock and Google Cloud only)
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
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (Fable 5, Mythos 5, Mythos Preview, Opus 5, Sonnet 5, Opus 4.7+) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- On Opus 5 and Sonnet 5, the `effort` parameter defaults to `high` on the Claude API and Claude Code (not claude.ai). On Opus 4.8, it defaults to `high` on every surface. Set `effort` explicitly for a different level.
- Fast mode (research preview, premium pricing) is available for Opus 5 and Opus 4.8 only — not Sonnet 5 or Fable 5.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
