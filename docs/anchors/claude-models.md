---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-18
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`, with Fable 5.2 above it as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason. All current models support text and image input, tool use, and adaptive thinking.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence for most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | High-volume, latency-sensitive tasks: classification, extraction, routing, subagents |

`claude-mythos-5-2` is the same price tier as Fable 5.2 but limited availability (verified organizations only, e.g. Cyber Verification Program). Not recommended for general use. Earlier Fable/Mythos 5 and 5.1 remain active at $10 / $50.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them for stability without memorizing a dated ID. Aliases still move; use the explicit ID for reproducibility across alias promotions.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date stop working on that date.

- `claude-sonnet-4-5` / `claude-sonnet-4-5-20250929` — **retires 2026-11-30 (imminent)**; replace with `claude-sonnet-5-5`
- `claude-opus-4-5-20251101` — active, not retiring sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — active, not retiring sooner than 2026-10-15; prefer `claude-haiku-5-5`
- `claude-opus-4-1-20250805` — retired 2026-08-05 (use `claude-opus-4-8` or newer)
- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — retired 2026-06-15
- `claude-mythos-preview` — deprecated 2026-06-09
- Legacy but still available: `claude-opus-4-6`, `claude-opus-4-7`, `claude-opus-4-8`, `claude-sonnet-4-6`, `claude-opus-5`, `claude-sonnet-5`
- Retired: `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-5-sonnet-*`, `claude-2.x`, `claude-instant-*`

Anthropic gives at least 60 days' notice before retiring a public model. When replacing a model, also update subagent `model:` fields.

## Tokenizer and API notes

- Opus 4.7 and later (including all 5.x models) use a newer tokenizer: 1M tokens is roughly 555k words, and the same text costs about 30% more tokens than on older models. Factor this into cost estimates when migrating.
- `temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` (400 error); omit them and steer via prompting.
- Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models; use adaptive thinking with `effort`.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5-5`
- **Long-running agentic work / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use explicit IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Batch API requests are 50% off; prompt-cache reads cost a small fraction of base input price.
