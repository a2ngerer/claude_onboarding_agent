---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-02
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x (Fable 5.1, Opus 5, Sonnet 5) plus Haiku 4.5 is the current lineup as of `last_updated`. Fable 5.1 sits above Opus 5 as the highest-capability generally available model, for demanding reasoning and long-horizon agentic work; Opus 5 is the default recommendation for most workloads. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5`             | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; default recommendation |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — balanced default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                   | Fastest model with near-frontier intelligence; subagent scans |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It has limited availability and is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). For the current generation the alias and the Claude API ID are the same string — e.g. `sonnet` and `claude-sonnet-5` both resolve to the same pinned snapshot.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on — they do not silently move to a newer checkpoint. Aliases from before the 4.6 generation were convenience pointers to a dated ID; from 4.6 on, the alias repeats the dateless ID.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Dates below are Anthropic's not-sooner-than retirement commitment for Anthropic-operated platforms (Claude API, Claude Platform on AWS, Microsoft Foundry); Bedrock and Google Cloud set their own dates.

- `claude-haiku-4-5-20251001` — not sooner than 2026-10-15 (closest upcoming retirement)
- `claude-sonnet-5` — not sooner than 2027-06-30
- `claude-opus-5` — not sooner than 2027-07-24
- `claude-fable-5-1` — not sooner than 2027-09-01
- Legacy, still available: `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`
- Retired except on Bedrock/Google Cloud: `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-haiku-3-5`
- Retired entirely: `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models — including every Claude 5.x model — use a newer tokenizer that produces roughly 30% more tokens for the same text than Claude Sonnet 4.6 and earlier. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Complex agentic coding / enterprise work:** `claude-opus-5`
- **Demanding reasoning / long-horizon agentic planning:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Prices above are standard per-MTok rates; prompt cache reads are 0.1x base input price (0.025x on Fable/Mythos 5.1), and Batch API requests are 50% off.
- Use dateless IDs (`claude-opus-5`) for production stability — every Claude model ID, dated or not, is a pinned snapshot from the 4.6 generation on.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
