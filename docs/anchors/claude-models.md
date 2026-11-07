---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-07
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5, all with a 1M-token context window and 128k max output. Official guidance: start with Opus 5.5 for most workloads; use Fable 5.1 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium         | High-volume, latency-sensitive tasks: classification, extraction, routing, subagents |

All current models use adaptive thinking. Every model ID is a pinned snapshot (dateless IDs since the 4.6 generation). Batch API requests are 50% off; prompt cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1).

`claude-mythos-5-1` is the Fable-class model without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field in subagent and skill frontmatter accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier — they move when Anthropic promotes a new default. Full IDs never move.

## Legacy (still available)

Not recommended for new work. Tentative earliest retirement dates in parentheses:

- `claude-fable-5` (Jun 2027), `claude-opus-5` (Jul 2027), `claude-sonnet-5` (Jun 2027)
- `claude-opus-4-8` (May 2027), `claude-opus-4-7` (Apr 2027), `claude-opus-4-6` (Feb 2027)
- `claude-sonnet-4-6` (Feb 2027)
- `claude-haiku-4-5-20251001` (**not sooner than 2026-10-15** — migrate to `claude-haiku-5-5`)
- `claude-opus-4-5-20251101` (**not sooner than 2026-11-24** — migrate to `claude-opus-5-5`)

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — deprecated; **retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-mythos-preview` — deprecated 2026-06-09
- Retired: `claude-opus-4-1-20250805` (2026-08-05), `claude-opus-4-20250514` and `claude-sonnet-4-20250514` (2026-06-15), `claude-3-haiku-20240307`, `claude-3-5-haiku-20241022`, `claude-3-7-sonnet-20250219`, `claude-3-5-sonnet-*`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-2.x`, `claude-instant-*`

Claude Code: fast mode for Opus 4.8 is deprecated and will be removed 2026-11-30; migrate to Opus 5.5.

## API parameter note

`temperature`, `top_p`, and `top_k` were removed in API version `2026-10-21` (400 error); omit them and steer behavior through prompting. Manual extended thinking (`budget_tokens`) is not accepted on models after Opus 4.6 / Sonnet 4.6 — use adaptive thinking and `effort`.

## Tokenizer note

Models from Opus 4.7 onward use a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full undated IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
