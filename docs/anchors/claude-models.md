---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-25
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated` (Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5). Fable sits above Opus as the highest-capability generally available tier. All current models have a 1M context window, 128k max output, and adaptive thinking. Default to the latest IDs below unless a project has pinned an older version.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable` | 1M      | 128k       | $8 / $40                  | Demanding reasoning, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / $0.50        | Fast, cheap, high-volume tasks, classification, routing, subagents |

`claude-mythos-5-2` is Fable 5.2 without dual-use safety measures. It is limited-availability (verified organizations only) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier and can differ by platform (e.g. Bedrock may lag the first-party default).

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Aliases move when Anthropic promotes a new default; use the IDs directly for reproducibility.

## Older models

Still available, but prefer the 5.5 family in new work:

- Fable 5.1 / 5, Opus 5, Sonnet 5 — previous 5.x generation (`claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`)
- `claude-opus-4-8`, `-4-7`, `-4-6`, `claude-sonnet-4-6` — 4.x generation, 1M context
- `claude-opus-4-5`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001` — 200k context

Retired on the first-party API (may persist on some cloud platforms): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`. Older 3.x / 2.x IDs (`claude-3-*`, `claude-2.*`, `claude-instant-1.2`) are long deprecated — never use them.

Announced retirement floors: Fable 5.2 not before 2027-11-09, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Tokenizer note

Opus 4.7 and every later model (including the whole 5.x family) use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads and agentic coding:** `claude-opus-5-5` (Anthropic's suggested starting point); `claude-sonnet-5-5` for speed/cost balance
- **Maximum capability / long-horizon agents:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use the dateless IDs for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Set `effort` explicitly when you need something other than the model's default.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
