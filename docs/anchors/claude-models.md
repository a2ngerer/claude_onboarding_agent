---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-11
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.2 sits above Opus as the highest-capability generally available model. Anthropic's guidance: start with Opus 5.5 for most workloads; use Fable 5.2 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning, long-horizon agentic work; adaptive thinking always on, default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

Mythos 5.2 is the Fable-class model without dual-use safety measures. It is limited-availability and not recommended for general use.

Legacy models (still available): Fable 5.1, Fable 5, Opus 5, Opus 4.8 / 4.7 / 4.6 / 4.5, Sonnet 5, Sonnet 4.6, Haiku 4.5. Retirement commitments for the current models: Fable 5.2 not before 2027-11-09, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default (e.g. `fable` now resolves to Fable 5.2; saved Fable 5.1 picks in Claude Code moved to `fable`).

## ID pinning behavior

Since the 4.6 generation, dateless model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases in Claude Code still move; for reproducibility across alias promotions, use the dateless ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- Fast mode for Opus 4.8 — deprecated, **removed 2026-11-30**; migrate to Opus 5.5 to keep the speedup
- `claude-sonnet-4-0`, `claude-opus-4-0` — retired 2026-06-15
- `claude-opus-4-1` — retired 2026-08-05
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Thinking and tokenizer notes

- Adaptive thinking is the thinking mode on current models, steered by the `effort` parameter. Manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is deprecated on Opus 4.6 / Sonnet 4.6 and not accepted on later models.
- Models since Opus 4.7 use a tokenizer that produces roughly 30% more tokens for the same text than older models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating.
- Batch API requests are 50% off; prompt-cache reads cost 10% of base input (5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.x / Mythos 5.x).

## Defaults

- **Most workloads and agentic coding:** `claude-opus-5-5`
- **Balanced everyday tasks:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
