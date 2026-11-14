---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-14
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.2 is the highest-capability generally available tier; Anthropic recommends Opus 5.5 as the starting point for most workloads and Fable 5.2 for demanding reasoning, long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable` | 1M      | 128k       | $8 / $40                  | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | high           | Balanced speed and intelligence |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / $0.50        | medium         | High-volume, latency-sensitive tasks and subagents |

All current models use adaptive thinking. Earlier Fable releases (`claude-fable-5-1`, `claude-fable-5`) remain available at $10 / $50; saved Fable 5.1 selections in Claude Code move to the `fable` alias (Fable 5.2) as of Claude Code 2.1.321. `claude-mythos-5-2` (and 5.1 / 5) is limited-availability for verified organizations and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier and move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Aliases (`opus`, `sonnet`, ...) are the moving pointers. Use the full ID for reproducibility across alias promotions.

## Legacy / retired

Do not use these IDs in new code or configs.

- Still available (legacy): `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-opus-4-5` (200k / 64k), `claude-sonnet-4-5` (200k / 64k), `claude-haiku-4-5-20251001` (200k / 64k, $1 / $5)
- Retired on the Claude API (may persist on some cloud platforms): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`
- Older generations: `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Announced earliest retirement dates for current models: Fable 5.2 not before 2027-11-09, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Tokenizer note

Opus 4.7 and later (including all 5.x models) use a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models. Factor this into cost estimates when migrating.

## Defaults

- **Most workloads and agentic coding:** `claude-opus-5-5` (or `claude-sonnet-5-5` for cost/speed balance)
- **Demanding reasoning / long-horizon agents:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases move when defaults are promoted.
- Set `effort` explicitly when you need a level other than the model's default.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
