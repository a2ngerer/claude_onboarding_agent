---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-18
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. The Fable tier sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

All current models have a 1M-token context window, 128k max output, and adaptive thinking.

| Tier   | Model ID            | Alias   | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|---------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | $10 / $50                 | high           | Demanding reasoning and long-horizon agentic work; thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`  | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; start here for most heavy workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| $2 / $10                  | high           | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | from $0.10 / $0.50        | medium         | Fast, cheap, high-volume tasks and subagents (classification, extraction, routing) |

Haiku 5.5 is $0.10 / $0.50 up to 100k input tokens and $0.50 / $2.50 above that. Batch API requests are 50% off. Cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.1).

`claude-mythos-5-1` is the Fable 5.1 counterpart without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them when you want stability without memorizing a dated ID. Short aliases still move; for reproducibility across alias promotions, use the full ID.

## Legacy (still available)

Fine for pinned projects; prefer the 5.5 IDs for new work.

- `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`
- `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001`

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5` — deprecated, retires 2026-11-30 (no longer on the legacy list)
- `claude-opus-4-1` — retired 2026-08-05
- `claude-sonnet-4-0`, `claude-opus-4-0` — retired 2026-06-15
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Models from Opus 4.7 onward (including all of the 5.x family) use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens is about 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5-5`
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Set `effort` explicitly when you need a level other than the model's default.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
