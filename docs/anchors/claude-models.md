---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-26
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current generation as of `last_updated`: Fable 5.2 (top tier), Opus 5.5, Sonnet 5.5, and Haiku 5.5. All support adaptive thinking, text and image input, and tool use. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks, classification, routing, subagents |

`claude-mythos-5-2` (and earlier Mythos 5 / 5.1) is the Fable counterpart without dual-use safety measures; limited availability via verification programs, not for general use.

Retirement commitments (Anthropic-operated platforms): Fable 5.2 not before 2027-11-09, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier and move when a new default is promoted. On cloud platforms the alias target can lag: Bedrock's `sonnet` still resolves to Sonnet 4.5, while Google Cloud and Foundry `sonnet` resolve to Sonnet 5.5.

## ID pinning behavior

Every Claude API model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Aliases are the only moving pointers.

## Older models (still listed)

- Previous 5.x: `claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`
- 4.x legacy: `claude-opus-4-8`, `-4-7`, `-4-6` (1M context); `claude-opus-4-5`, `claude-sonnet-4-5` (200k); `claude-sonnet-4-6` (1M); `claude-haiku-4-5-20251001` (200k)
- Extended thinking (`budget_tokens`) is deprecated on Opus 4.6 / Sonnet 4.6 and rejected on later models; use adaptive thinking plus `effort`.

## Retired — do not use

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` are retired on the Claude API (and on Foundry); only some cloud partners still serve them.
- All `claude-3-*`, `claude-2.*`, and `claude-instant-1.2` IDs are long deprecated.

## Tokenizer note

Models from Opus 4.7 onward share a newer tokenizer that yields roughly 30% more tokens per text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Most demanding workloads (start here when unsure on the API):** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; aliases move when defaults are promoted.
- Re-run your eval suite when migrating; prompts tuned for one family may need light adjustment. See each model's migration guide.
