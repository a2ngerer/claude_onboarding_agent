---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-11
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Claude Opus 5, Claude Sonnet 5, and Claude Fable 5 replaced the 4.x-generation defaults (Opus 4.8, Sonnet 4.6) as of late July / June 2026. The Fable 5 tier sits above Opus as the highest-capability generally available model.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Next-generation intelligence for long-running agents |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10 through 2026-08-31, then $3 / $15 | The best combination of speed and intelligence — balanced default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing but ships without dual-use safety measures. It is invitation-only (Project Glasswing) and not recommended for general use. `claude-mythos-preview` is a separate, also invitation-only preview track.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy (still available)

Consider migrating to the current models above for improved performance and (for Sonnet/Opus) larger max-output limits.

- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy Opus, $5 / $25 per MTok
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy Sonnet, $3 / $15 per MTok

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0` — **retired** (except on Bedrock and Google Cloud)
- `claude-opus-4-1` — **retired 2026-08-05** (except on Bedrock and Google Cloud)
- `claude-haiku-3-5` / `claude-3-5-haiku-20241022` — **retired** (except on Bedrock and Google Cloud)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (Fable 5, Opus 5, Sonnet 5, Mythos 5, and Opus 4.7+) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- On Opus 5 and Sonnet 5, the `effort` parameter defaults to `high` on the Claude API and Claude Code (Opus 4.8 also defaults to `high` on every surface, including claude.ai). Set `effort` explicitly for a different level.
- Fast mode (research preview) gives faster output for Opus 5 and Opus 4.8 at premium pricing ($10 / $50 per MTok); Claude API only, not available with the Batch API.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
