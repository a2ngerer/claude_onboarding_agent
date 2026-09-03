---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-03
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`: Fable 5.1, Opus 5, Sonnet 5, and Haiku 4.5. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking is always on |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; official "start here if unsure" default |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — balanced default for most coding tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, every Claude model ID — including dateless IDs like `claude-opus-5` — is a pinned snapshot, not a moving pointer. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Deprecated / retiring

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4` — retired, except on Bedrock/Google Cloud (Opus 4.1) or Google Cloud only (Opus 4)
- `claude-sonnet-4-0` / `claude-sonnet-4` — retired, except on Bedrock and Google Cloud
- `claude-haiku-3-5` — retired, except on Bedrock and Google Cloud
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-*`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2` — fully retired

**Legacy (still available, superseded by the 5.x family):** `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

**Retirement commitments for current models** (Anthropic-operated platforms; "not sooner than"): Fable 5.1 — 2027-09-01. Opus 5 — 2027-07-24. Sonnet 5 — 2027-06-30. Haiku 4.5 — 2026-10-15. Bedrock and Google Cloud set their own dates.

## Tokenizer note

Claude 4.7 and later — which includes every current 5.x model — use a newer tokenizer that produces roughly 30% more tokens for the same text than the previous tokenizer (still used by Sonnet 4.6 and earlier). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (balanced default):** `claude-sonnet-5`
- **Deep reasoning / long-horizon agentic planning:** `claude-fable-5-1`
- **Official "unsure which model to use" starting point:** `claude-opus-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Prompt-cache reads are priced at 0.1x the base input price on most models, but only 0.025x on Fable 5.1 and Mythos 5.1 — factor this into cache-heavy cost comparisons.
