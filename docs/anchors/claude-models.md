---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-07
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`, alongside Haiku 4.5. Fable 5.1 sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`           | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; recommended starting point for most workloads |
| Sonnet | `claude-sonnet-5-5`         | `sonnet` | 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — everyday coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku`  | 200k    | 64k        | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` (like Mythos 5 before it) is the Fable-class model without dual-use safety measures. It is limited-availability (verified organizations only) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). In Claude Code the aliases follow the newest version of each tier, so they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Only Claude Code aliases move. Use the full ID when you need reproducibility across promotions.

## Retirement commitments

Anthropic-operated platforms: Fable 5.1 not before 2027-09-01, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 4.5 not before **2026-10-15** (plan a migration).

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — retired (remain only on some partner clouds)
- Legacy, still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`
- Older: `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (including all 5.x) use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / long-running agentic work:** `claude-opus-5-5` (default effort `medium`)
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Prefer full IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Manual extended thinking (`budget_tokens`) is not accepted on later models; use adaptive thinking steered by `effort`.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
