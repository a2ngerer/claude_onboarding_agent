---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-14
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`, having succeeded the 4.x line: Fable 5.1, Opus 5, Sonnet 5, and Haiku 4.5 are the current defaults. Fable 5, Opus 4.8, Opus 4.7, Opus 4.6, Opus 4.5, Sonnet 4.6, and Sonnet 4.5 are legacy but still available. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5`       | `opus`   | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — best speed/intelligence tradeoff for most tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` and `claude-mythos-5` are the same-generation models without dual-use safety measures. Both are invitation-only (limited availability) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including undated IDs used from the 4.6 generation on (e.g. `claude-opus-5`, `claude-sonnet-5`). Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — **retired** on the Claude API (Bedrock and Google Cloud set their own, later lifecycle dates for these)
- `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-5`, `claude-fable-5` — legacy, still available
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Current-generation retirement commitments (earliest possible date, not a scheduled shutdown): Haiku 4.5 not sooner than 2026-10-15; Sonnet 5 not sooner than 2027-06-30; Opus 5 not sooner than 2027-07-24; Fable 5.1 not sooner than 2027-09-01.

## Tokenizer note

Claude 4.7 and later models — including all current Fable 5.1 / Opus 5 / Sonnet 5 / Mythos models — use a newer tokenizer that produces roughly 30% more tokens for the same text. Sonnet 4.6 and earlier use the previous tokenizer. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability / long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 5's $2/$10 per-MTok pricing is the permanent rate, not an introductory one — a previously planned increase to $3/$15 was cancelled.
