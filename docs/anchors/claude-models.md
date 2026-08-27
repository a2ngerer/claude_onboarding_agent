---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-27
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 4.x / 5.x is the current family as of `last_updated`. Claude Opus 5 and Claude Sonnet 5 are now generally available and are the recommended Opus/Sonnet picks, superseding Opus 4.8 and Sonnet 4.6. The Fable 5 tier sits above Opus for maximum capability. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`            | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents, adaptive thinking |
| Opus   | `claude-opus-5`             | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — default for most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` is the same model as Fable 5 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. For the 4.6 generation and later, the dateless model ID and the alias are the same pinned snapshot.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID.

## Legacy / retiring

Legacy models stay available but are no longer the recommended default for new work:

- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy, still available
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy, still available
- `claude-opus-4-1`, `claude-opus-4`, `claude-sonnet-4`, `claude-haiku-3-5` — retired on the Claude API (still available on Bedrock and Google Cloud)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-*`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2` — long retired, do not use

Retirement commitments (not sooner than): Fable 5 — 2027-06-09; Opus 5 — 2027-07-24; Sonnet 5 — 2027-06-30; Haiku 4.5 — 2026-10-15.

## Tokenizer note

Claude Opus 4.7 and later (including Fable 5, Mythos 5, Opus 5, Sonnet 5) use a newer tokenizer that produces roughly 30% more tokens for the same text than the tokenizer used by Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models. On the newer tokenizer, a 1M-token context window holds roughly 555k words; on the older tokenizer it held roughly 750k words per 1M tokens.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex enterprise work:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`, `claude-sonnet-5`) for production stability; they are pinned snapshots since the 4.6 generation.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 5's $2/$10 per-MTok pricing was introductory at launch and is now the standard, permanent rate.
