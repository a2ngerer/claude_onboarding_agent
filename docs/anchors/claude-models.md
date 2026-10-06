---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-06
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

The Claude 5 family (Fable 5.1, Opus 5.5, Sonnet 5.5) plus Haiku 4.5 is the current lineup as of `last_updated`. Anthropic recommends starting with Opus 5.5 for most workloads and Fable 5.1 for demanding reasoning and long-horizon agentic work. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`           | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5`         | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | 200k    | 64k        | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` (and `claude-mythos-5`) is the Fable-class model without dual-use safety measures. It is limited-availability (Project Glasswing), invitation-only, and not recommended for general use.

## Aliases

The Claude Code `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases resolve to the current recommended snapshot for that tier and move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). For models before 4.6, the API alias (e.g. `claude-haiku-4-5`) is a convenience pointer to the dated ID. Claude Code aliases still move; use the full ID for reproducibility.

## Legacy and retired

Still available but superseded — avoid in new code:

- `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`
- `claude-sonnet-4-6`, `claude-sonnet-4-5`

Retired on the Claude API (may remain on Bedrock / Google Cloud): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-3-5-haiku-20241022`.

Long deprecated: `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`.

Retirement commitments (Anthropic-operated platforms): Haiku 4.5 not sooner than 2026-10-15; Fable 5.1 not sooner than 2027-09-01; Opus 5.5 not sooner than 2027-09-22; Sonnet 5.5 not sooner than 2027-09-28.

## Tokenizer note

Claude 4.7 and later models (including the whole Claude 5 family) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Hard agentic coding / most demanding workloads:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use full pinned IDs for production stability; Claude Code aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt-cache reads cost 0.1x base input price (0.05x on Opus 5.5, 0.025x on Fable 5.1); the Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
