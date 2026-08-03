---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-03
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Opus 5 and Claude Sonnet 5 are the current default tiers as of `last_updated`, superseding Opus 4.8 and Sonnet 4.6. Claude Fable 5 remains the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25 (fast mode: $10 / $50) | Complex agentic coding, enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $3 / $15 (introductory $2 / $10 through 2026-08-31) | Best combination of speed and intelligence — Claude Code default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing; it and the invitation-only `claude-mythos-preview` are part of Project Glasswing and are not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy (still available, prefer current tier for new configs)

- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101` — $5 / $25
- `claude-sonnet-4-6`, `claude-sonnet-4-5-20250929` — $3 / $15

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date will stop working on that date.

- `claude-opus-4-1-20250805` — **retires 2026-08-05 (imminent)**
- `claude-opus-4-0`, `claude-sonnet-4-0` — retired 2026-06-15; no longer available on the Claude API
- `claude-opus-4` — retired, except on Google Cloud
- `claude-sonnet-4` — retired, except on Bedrock and Google Cloud
- `claude-haiku-3-5` — retired, except on Bedrock and Google Cloud
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Fable 5, Mythos 5, Sonnet 5, and Opus 4.7+ use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from older models.

## Effort defaults

On Opus 4.8, the `effort` parameter defaults to `high` on all surfaces (API, Claude Code, claude.ai). On Opus 5 and Sonnet 5, it defaults to `high` on the Claude API and in Claude Code only. Set `effort` explicitly to use a different level.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex coding:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 5's introductory pricing ($2/$10 per MTok) reverts to standard ($3/$15) on 2026-09-01 — don't hardcode the promotional rate in cost estimates that outlive that date.
