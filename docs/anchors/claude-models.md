---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-24
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. All four have a 1M-token context window, 128k max output, adaptive thinking, and a Jun 2026 knowledge cutoff. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium`; start here for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance; default effort `high` |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / $0.50        | High-volume, latency-sensitive tasks: classification, extraction, routing, subagent scans |

`claude-mythos-5-1` is the Fable counterpart without dual-use safety measures. It is invitation-only and not recommended for general use. Batch API requests are 50% off.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. In Claude Code, the `fable` alias falls back to the previous Fable model if the newest one is not available to your organization.

## ID pinning behavior

Every current model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Use them when you want stability without memorizing a dated ID. Aliases still move; for reproducibility across alias promotions, use the full ID.

## Legacy and deprecated

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — **deprecated, retires 2026-11-30** (replace with `claude-sonnet-5-5`)
- `claude-opus-4-5-20251101` — active, not sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — legacy, not sooner than 2026-10-15
- `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5` — legacy, still available
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6` — legacy, still available
- `claude-mythos-preview` — deprecated since 2026-06-09
- Retired (requests fail): `claude-opus-4-1-20250805`, `claude-opus-4-20250514`, `claude-sonnet-4-20250514`, `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`, and all Claude 3 Opus/Sonnet, 3.5 Sonnet, 2.x, and Instant models

## API parameter changes

`temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` (400 error); omit them and steer with prompting. Manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models — use adaptive thinking with `effort`.

## Tokenizer note

Models since Opus 4.7 use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and most workloads:** `claude-opus-5-5`
- **Fast, balanced coding and general tasks:** `claude-sonnet-5-5`
- **Hardest reasoning and long-horizon agents:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
