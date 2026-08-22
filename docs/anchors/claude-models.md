---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-22
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current generation as of `last_updated`: **Opus 5**, **Sonnet 5**, and **Fable 5** all shipped this generation, alongside the still-current **Haiku 4.5**. Fable 5 (and its Mythos 5 counterpart) remain the highest-capability tier, sitting above Opus. Start with Opus 5 for complex agentic coding and enterprise work; use Fable 5 only when a workload needs maximum available capability.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks; defaults to high effort |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing; it is invitation-only (Project Glasswing) and not recommended for general use. `claude-opus-4-8` remains available as the prior Opus tier ($5/$25, same pricing as Opus 5).

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0` — **retired**
- `claude-opus-4-1` — **retired**, except on Bedrock and Google Cloud
- `claude-opus-4` — **retired**, except on Google Cloud
- `claude-sonnet-4` — **retired**, except on Bedrock and Google Cloud
- `claude-haiku-3-5` — **retired**, except on Bedrock and Google Cloud
- `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy, still available ($5/$25)
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy, still available ($3/$15 — pricier than current Sonnet 5)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Fable 5, Mythos 5, and Opus 4.7+ use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Effort defaults

On Opus 4.8, the `effort` parameter defaults to `high` on every surface (API, Claude Code, claude.ai). On Opus 5 and Sonnet 5, it defaults to `high` on the Claude API and Claude Code only — set it explicitly if you need a different level or surface-specific behavior.

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
