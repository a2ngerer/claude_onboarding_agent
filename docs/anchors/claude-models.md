---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-17
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`, led by Fable 5.1 above Opus 5.5. Anthropic's guidance: start with Opus 5.5 for most workloads; use Fable 5.1 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short on your evals. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high           | Maximum capability, demanding reasoning, long-horizon agents |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | medium         | Fast, cheap, high-volume tasks, classification, routing, subagents |

All current models use adaptive thinking (steered by `effort`); manual `thinking.type: "enabled"` with `budget_tokens` is not accepted on later models. Batch API requests are 50% off. Haiku 5.5 pricing is higher for prompts over 100K tokens ($0.50 / $2.50).

`claude-mythos-5-1` is the Fable 5.1 counterpart without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. If the newest Fable is unavailable to an organization, the `fable` alias retries once on the previous Fable model.

## ID pinning behavior

Since the 4.6 generation, dateless model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them for stability without memorizing a dated ID. Aliases in Claude Code still move; for reproducibility across alias promotions, use the dateless ID directly.

## Legacy (still available)

`claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101` (retires not sooner than 2026-11-24), `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` (retires not sooner than 2026-10-15). Prefer the 5.5 IDs for new work.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — deprecated; **retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-opus-4-1-20250805` — retired 2026-08-05
- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — retired 2026-06-15
- `claude-3-haiku-20240307` — retired 2026-04-20
- `claude-3-5-haiku-20241022`, `claude-3-7-sonnet-20250219` — retired 2026-02-19
- `claude-3-opus-20240229` — retired 2026-01-05
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022` — retired 2025-10-28
- `claude-mythos-preview` — deprecated 2026-06-09
- `claude-3-sonnet-20240229`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2` and earlier — retired

## Parameter and tokenizer notes

- Claude 4.7 and later models return a 400 error if `temperature`, `top_p`, or `top_k` is set to a non-default value. Omit them and steer behavior through prompting.
- Models from Opus 4.7 onward share a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / long-running agentic work:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
