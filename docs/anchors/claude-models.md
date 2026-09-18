---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-18
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Fable 5.1 is the current highest-capability generally available model, for demanding reasoning and long-horizon agentic work. Claude Opus 5 is the default recommendation for complex agentic coding and enterprise work. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|---------|---------|------------|----------------------------|-------------------|
| Fable  | `claude-fable-5-1`          | `fable` | 1M      | 128k       | $10 / $50                  | Maximum capability, demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5`             | `opus`  | 1M      | 128k       | $5 / $25                   | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`           | `sonnet`| 1M      | 128k       | $2 / $10                   | Balanced default — best combination of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k    | 64k        | $1 / $5                    | Fastest model with near-frontier intelligence; subagent scans |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It is invitation-only (limited availability) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, every dateless Claude API model ID (e.g. `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5-1`) is a pinned snapshot, not a moving pointer. Use them when you want stability without memorizing a full dated ID. Short CLI aliases (`opus`, `sonnet`, etc.) still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Legacy / deprecated / retiring

Do not use these in new code or configs.

- **Legacy (still available):** `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.
- **Retired** (Anthropic-operated platforms; Bedrock/Google Cloud set their own dates): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-haiku-3-5`.
- **Fully retired everywhere:** `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`.

Retirement commitments (not sooner than): Fable 5.1 — 2027-09-01; Opus 5 — 2027-07-24; Sonnet 5 — 2027-06-30; Haiku 4.5 — 2026-10-15.

## Tokenizer note

Claude 4.7+ and the Mythos line use a newer tokenizer that produces roughly 30% more tokens for the same text than the previous tokenizer (Sonnet 4.6 and earlier). The 1M-token context window is ~555k words on the new tokenizer, vs. ~750k words on the old one. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Complex agentic coding / enterprise / deep reasoning:** `claude-opus-5`
- **Maximum capability / long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
