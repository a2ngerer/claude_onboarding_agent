---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-20
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. The Fable tier sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason. If unsure where to start, use Opus 5.5; move to Fable 5.1 for demanding reasoning and long-horizon agentic work.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k; $0.50 / $2.50 above) | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` is the Fable 5.1 tier without dual-use safety measures. It is limited-availability and not recommended for general use. All 5.x models use adaptive thinking; Batch API requests are 50% off.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Use them when you want stability without memorizing a dated ID. Aliases in Claude Code still move; for reproducibility across alias promotions, use the full ID directly.

## Legacy and retiring

Legacy models still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101` (not sooner than 2026-11-24), `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` (not sooner than 2026-10-15 — migrate to `claude-haiku-5-5`).

Do not use these in new code or configs:

- `claude-sonnet-4-5-20250929` — deprecated, **retires 2026-11-30** (use `claude-sonnet-5-5`)
- `claude-mythos-preview` — deprecated 2026-06-09
- `claude-opus-4-1-20250805` — retired 2026-08-05
- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — retired 2026-06-15
- `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022` — retired 2026-02-19
- `claude-3-haiku-20240307` — retired 2026-04-20
- `claude-3-opus-20240229`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229` — retired
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2` — retired

## API parameter note

`temperature`, `top_p`, and `top_k` return a 400 error when set to non-default values on Claude 4.7 and later models. Omit them and steer behavior through prompting. Extended thinking (`thinking.type: "enabled"` with `budget_tokens`) is not accepted on later models; use adaptive thinking and the `effort` parameter.

## Tokenizer note

Models from Opus 4.7 onward use a newer tokenizer that produces roughly 30% more tokens for the same text (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic work / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt cache reads are heavily discounted (e.g. $0.10 / MTok on Sonnet 5.5, $0.25 / MTok on Fable 5.1); structure prompts for caching on repeated agent loops.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
