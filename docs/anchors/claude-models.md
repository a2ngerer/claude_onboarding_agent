---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-29
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current flagship generation as of `last_updated`: Opus 5, Sonnet 5, Fable 5, and Mythos 5. Haiku 4.5 remains the fast/cheap tier. Fable 5 is still the highest-capability generally available model; Opus 5 replaces Opus 4.8 as the recommended tier for complex agentic coding and enterprise work, and Sonnet 5 replaces Sonnet 4.6 as the balanced default. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agentic work, adaptive thinking (always on) |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — new default for most coding/general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fastest, near-frontier intelligence; fast, cheap subagents |

`claude-mythos-5` is the same generation as Fable 5 but without dual-use safety measures. It has limited/invitation-only availability and is priced the same as Fable 5 ($10/$50).

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude API model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5`). Aliases for pre-4.6 models resolve to a dated ID and can move; dateless-ID aliases just repeat the pinned ID.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- `claude-opus-4-1` — retired 2026-08-05 (still available on Bedrock and Google Cloud only)
- `claude-opus-4-0` — retired 2026-06-15 (still available on Bedrock and Google Cloud only)
- `claude-sonnet-4-0` — retired 2026-06-15 (still available on Bedrock and Google Cloud only)
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy, still available (superseded by Opus 5)
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy, still available (superseded by Sonnet 5)
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Retirement commitments (current-generation models)

Anthropic's minimum-availability commitment (Anthropic-operated platforms only): Fable 5 not sooner than 2027-06-09; Opus 5 not sooner than 2027-07-24; Sonnet 5 not sooner than 2027-06-30; Haiku 4.5 not sooner than 2026-10-15.

## Tokenizer note

Claude 4.7-and-later models — including Sonnet 5, Opus 5, Fable 5, and Mythos 5 — use a newer tokenizer that produces roughly 30% more tokens for the same text. Sonnet 4.6 and earlier use the previous tokenizer. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`, `claude-sonnet-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Sonnet 5's $2/$10 per-MTok pricing was introductory but is now the permanent standard rate — the previously announced 2026-09-01 increase to $3/$15 was cancelled.
- Extended (manual budget-based) thinking is deprecated on Opus 4.6/Sonnet 4.6 and not accepted at all on Opus 5, Sonnet 5, Fable 5, or Mythos 5 — those models only support adaptive thinking via the `effort` parameter.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
