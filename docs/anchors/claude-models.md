---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-17
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.2 sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; start here for most hard workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

`claude-mythos-5-2` is the Fable 5.2 counterpart without dual-use safety measures. It is limited availability (Cyber Verification Program) and not recommended for general use.

Earlier 5.x IDs remain available: `claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them when you want stability without memorizing a full dated ID. Aliases still move; for reproducibility across alias promotions, use the full ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` — retired on the Claude API (may remain on some partner clouds)
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy, still available
- `claude-sonnet-4-6`, `claude-sonnet-4-5` — legacy, still available
- `claude-haiku-4-5-20251001` — legacy, still available (200k context, 64k output)
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

Current models are committed to no retirement sooner than Sep–Nov 2027 (Opus 5.5: Sep 22, 2027; Sonnet 5.5: Sep 28, 2027; Haiku 5.5: Oct 7, 2027; Fable 5.2: Nov 9, 2027).

## Tokenizer note

Models since Opus 4.7 use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / long-running agentic work:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Thinking is adaptive on current models, steered by `effort`; manual `budget_tokens` extended thinking is not accepted on later models.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
