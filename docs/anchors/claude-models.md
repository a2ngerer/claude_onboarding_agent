---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-30
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 / Fable 5.1 is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability generally available model. Start with Opus 5.5 for most workloads; step up to Fable 5.1 for demanding reasoning and long-horizon agentic work, or when evals on Opus 5.5 at higher effort still fall short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID           | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|--------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1` | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on, default effort `high` |
| Opus   | `claude-opus-5-5`  | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; adaptive thinking always on, default effort `medium` |
| Sonnet | `claude-sonnet-5-5`| `sonnet` | 1M      | 128k       | $2 / $10                  | Best balance of speed and intelligence — most coding and general tasks |
| Haiku  | `claude-haiku-5-5` | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

`claude-mythos-5-1` is the Fable 5.1 sibling without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. The `fable` alias falls back to the previous Fable model if the newest one is not available to your organization (Claude Code 2.1.301+).

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them for stability without memorizing a dated ID. Claude Code aliases still move; use the full ID for reproducibility across alias promotions. Write IDs with hyphens, not dots (`claude-opus-4-8`, not `claude-opus-4.8`).

## Legacy (still available)

Active but no longer the recommended default: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101` (not sooner than 2026-11-24), `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` (not sooner than 2026-10-15).

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — deprecated, **retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-opus-4-1-20250805` — retired 2026-08-05
- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — retired 2026-06-15
- `claude-3-haiku-20240307` — retired 2026-04-20
- `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022` — retired 2026-02-19
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022` — retired 2025-10-28
- `claude-3-opus-20240229` — retired 2026-01-05
- `claude-3-sonnet-20240229`, `claude-2.1`, `claude-2.0` — retired 2025-07-21
- `claude-instant-1.2` and Claude 1.x — retired 2024-11-06

## API parameter note

`temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` (400 error when set). Earlier versions reject non-default values on Claude 4.7+ models. Omit them and steer behavior through prompting. Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on current models; use adaptive thinking with `effort`.

## Tokenizer note

Opus 4.7 and later models use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from pre-4.7 models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic work / planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt-cache reads cost 10% of base input (5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.1); Batch API requests are 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
