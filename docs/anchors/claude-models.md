---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-10
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated` (Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5). Fable sits above Opus as the highest-capability generally available tier. All current models have a 1M context window, 128k max output, and adaptive thinking. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high           | Demanding reasoning and long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; recommended starting point |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Balanced default — speed plus intelligence for most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium         | High-volume, latency-sensitive tasks (classification, extraction, routing) and subagent scans |

Claude Mythos 5.1 is the Fable-class model without dual-use safety measures. It is limited-availability and not recommended for general use.

Legacy models still available: Fable 5 (`claude-fable-5`), Opus 5 (`claude-opus-5`), Opus 4.8 / 4.7 / 4.6 / 4.5, Sonnet 5 (`claude-sonnet-5`), Sonnet 4.6, Haiku 4.5 (`claude-haiku-4-5-20251001`).

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Retired IDs no longer work.

- `claude-sonnet-4-0` — retired (was 2026-06-15)
- `claude-opus-4-0` — retired (was 2026-06-15)
- `claude-opus-4-1` — retired (was 2026-08-05)
- `claude-sonnet-4-5` — legacy; prefer Sonnet 5.5
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Opus 4.7 and every later model (including the 5.x family) use a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / planning (Anthropic's recommended starting point):** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use undated IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Retirement commitments (not sooner than): Fable 5.1 2027-09-01, Opus 5.5 2027-09-22, Sonnet 5.5 2027-09-28, Haiku 5.5 2027-10-07.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
