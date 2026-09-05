---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-05
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Claude Fable 5.1 is the highest-capability generally available model; Claude Opus 5 is the default for complex agentic coding and enterprise work; Claude Sonnet 5 is the balanced default. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias               | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|----------------------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `claude-fable-5-1`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work |
| Opus   | `claude-opus-5`             | `claude-opus-5`     | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work |
| Sonnet | `claude-sonnet-5`           | `claude-sonnet-5`   | 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — balanced default |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`  | 200k    | 64k        | $1 / $5                   | Fastest model with near-frontier intelligence; subagent scans |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It has limited, invitation-only availability and is not recommended for general use.

## Aliases

Two distinct alias concepts exist — don't conflate them:

- **Claude API alias** (e.g. `claude-sonnet-5`): for the 4.6-generation and later, this is the *same pinned snapshot* as the dateless model ID, not a moving pointer. The exception is Haiku, whose alias `claude-haiku-4-5` points at the dated snapshot `claude-haiku-4-5-20251001`.
- **Claude Code `model:` field short alias** (`fable`, `opus`, `sonnet`, `haiku`, plus `inherit`): a product-level convenience that resolves to whatever Anthropic currently recommends for that tier. These *do* move when Anthropic promotes a new default — use a full model ID instead of the short alias if you need reproducibility across promotions.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers.

## Legacy (still available, not deprecated)

Superseded by the current lineup but still callable: `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

## Retirement commitments (Anthropic-operated platforms)

- Claude Fable 5.1 — not sooner than 2027-09-01
- Claude Opus 5 — not sooner than 2027-07-24
- Claude Sonnet 5 — not sooner than 2027-06-30
- Claude Haiku 4.5 — not sooner than 2026-10-15

Bedrock and Google Cloud set their own, independent retirement dates for the same models.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4`, `claude-sonnet-4`, `claude-haiku-3-5` — retired except on Bedrock and Google Cloud
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (and Claude Mythos Preview) use a newer tokenizer that produces roughly 30% more tokens for the same text than the previous generation. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex enterprise work:** `claude-opus-5`
- **Maximum capability, long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation.
- Use Claude Code short aliases (`opus`, `sonnet`, etc.) only where you want to always track Anthropic's current recommendation for a tier — they move when defaults are promoted, full IDs don't.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
