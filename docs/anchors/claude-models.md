---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-29
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. The Fable tier sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; recommended starting point for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — everyday coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

`claude-mythos-5-1` is the Mythos counterpart of Fable 5.1 without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier. The `fable` alias falls back to the previous Fable model if the newest one is not available to your organization.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Use them when you want stability without memorizing a dated ID. Aliases in Claude Code still move when Anthropic promotes a new default.

## Thinking and effort

Adaptive thinking is the only thinking mode on current models; manual `thinking.type: "enabled"` with `budget_tokens` is not accepted on later models. Default API effort: `high` for Fable 5.1 and Sonnet 5.5, `medium` for Opus 5.5 and Haiku 5.5. Set `effort` explicitly to change it.

## Legacy (still available)

Use only when a project has pinned them for a reason: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`.

## Deprecated / retired

Do not use these IDs in new code or configs. They are absent from the models overview's available list; check the model deprecations page for exact dates.

- `claude-sonnet-4-5`, `claude-sonnet-4-0`, `claude-opus-4-1`, `claude-opus-4-0`
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

Opus 4.7 and every later model use a newer tokenizer that produces roughly 30% more tokens for the same text (1M tokens ≈ 555k words, versus ≈ 750k before). Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads and agentic coding:** `claude-opus-5-5`
- **Everyday tasks, speed-sensitive work:** `claude-sonnet-5-5`
- **Hardest reasoning / long-horizon agents:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
