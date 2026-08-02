---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-02
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Opus 5 and Sonnet 5 are now the active Opus/Sonnet tiers, replacing Opus 4.8 and Sonnet 4.6 as the recommended defaults (those two are now legacy, still available but no longer recommended). Fable 5 sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents, adaptive thinking |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10 through 2026-08-31, then $3 / $15 | Best combination of speed and intelligence — Claude Code default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing but without dual-use safety measures. It is invitation-only (Project Glasswing) and not recommended for general use. `claude-mythos-preview` is deprecated in favor of it.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy (still active, no longer recommended)

- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy Opus snapshots, still available
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy Sonnet snapshots, still available

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date will stop working on that date.

- `claude-opus-4-1` (`claude-opus-4-1-20250805`) — **deprecated, retires 2026-08-05 (imminent)**; migrate to `claude-opus-5`
- `claude-sonnet-4-0` (`claude-sonnet-4-20250514`) — retired 2026-06-15
- `claude-opus-4-0` (`claude-opus-4-20250514`) — retired 2026-06-15
- `claude-3-7-sonnet-20250219` — retired 2026-02-19
- `claude-3-5-haiku-20241022` — retired 2026-02-19
- `claude-3-haiku-20240307` — retired 2026-04-20
- `claude-3-opus-20240229` — retired 2026-01-05
- `claude-3-sonnet-20240229`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Fable 5, Mythos 5, Opus 4.7+, and Sonnet 5 use a new tokenizer that produces roughly 30% more tokens for the same text. Sonnet 4.6 and earlier use the previous tokenizer. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- On Opus 5 and Sonnet 5, the `effort` parameter defaults to `high` on the Claude API and Claude Code (not on claude.ai). Set it explicitly to use a different level.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
