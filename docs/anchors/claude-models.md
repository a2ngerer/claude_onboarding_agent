---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-20
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current generation as of `last_updated`. Fable 5.1 sits above Opus 5 as the highest-capability generally available model; Opus 5 and Sonnet 5 are the newest general-purpose tiers, superseding Opus 4.8 and Sonnet 4.6 as defaults. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding, enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — balanced default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fastest model with near-frontier intelligence, subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. Aliases still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Legacy (still available, superseded by the 5.x generation)

`claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5` — usable but no longer the recommended default for their tier.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0` — retired 2026-06-15
- `claude-opus-4-0` — retired 2026-06-15
- `claude-opus-4-1` — retired, except on Bedrock and Google Cloud
- `claude-sonnet-4` — retired, except on Bedrock and Google Cloud
- `claude-opus-4` — retired, except on Google Cloud
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

Claude 4.7 and later models (including the entire 5.x generation and Mythos Preview) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Pricing note

Claude Sonnet 5's $2/$10-per-MTok launch pricing is now standard and permanent — the previously scheduled increase to $3/$15 was cancelled. Prompt-cache reads cost 0.1x the base input price on most models, but 0.025x on Fable 5.1 and Mythos 5.1.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex coding:** `claude-opus-5`
- **Maximum capability / long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
