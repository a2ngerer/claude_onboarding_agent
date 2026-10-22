---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-22
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Anthropic's guidance is to start with Opus 5.5 for most workloads, and to move to Fable 5.1 for demanding reasoning and long-horizon agentic work or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID           | Alias   | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|--------------------|---------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1` | `fable` | 1M      | 128k       | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`  | `opus`  | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5`| `sonnet`| 1M      | 128k       | $2 / $10                  | high           | Best speed/intelligence balance for most coding tasks |
| Haiku  | `claude-haiku-5-5` | `haiku` | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k; $0.50 / $2.50 above) | medium | Fast, cheap, high-volume tasks, classification, routing, subagents |

All current models use adaptive thinking and a reliable knowledge cutoff of Jun 2026. Anthropic's earliest retirement commitments are Sep 2027 (Fable 5.1) through Oct 2027 (Haiku 5.5).

`claude-mythos-5-1` (and `claude-mythos-5`) is the same model as Fable without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier and move when Anthropic promotes a new default. Claude Code v2.1.301+ falls back once to the previous Fable model if the newest one is not available to your organization.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs (e.g. `claude-opus-5-5`) used from the 4.6 generation on. Aliases still move; for reproducibility across alias promotions, use the full ID.

## Legacy and retired

Legacy (still available, avoid in new configs): `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`.

Retired (stop working on the first-party API; some persist on Bedrock / Google Cloud): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-3-5-haiku-20241022`.

Older, also unusable in new code:

- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Opus 4.7 and later models (including the 5.x family) use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Prefer full IDs for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Batch API requests are 50% off; prompt cache reads cost a fraction of base input (e.g. $0.10 / MTok on Sonnet 5.5, $0.20 on Opus 5.5).
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
