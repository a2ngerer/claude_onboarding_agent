---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-28
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 / Fable 5.1 is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; recommended starting point for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — everyday coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | Fastest; classification, extraction, routing, and subagent scans |

`claude-mythos-5-1` is the Fable 5.1 counterpart without dual-use safety measures. It is limited-availability and not recommended for general use.

Default API effort: Fable 5.1 `high`, Opus 5.5 `medium`, Sonnet 5.5 `high`, Haiku 5.5 `medium`. Set `effort` explicitly to use a different level.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier — they move when Anthropic promotes a new default. If the newest Fable model is unavailable, Claude Code retries the `fable` alias once on the previous Fable model.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Use them when you want stability without memorizing a dated ID. Aliases still move; for reproducibility across alias promotions, use the full ID.

## Legacy and retiring

Legacy models are still available but receive no updates. Do not use deprecated or retired IDs in new code or configs.

- Legacy (active): `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6`
- `claude-opus-4-5-20251101` — active, not retiring sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — active, not retiring sooner than 2026-10-15
- `claude-sonnet-4-5-20250929` — **deprecated, retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-mythos-preview` — deprecated since 2026-06-09
- Retired (requests fail): `claude-opus-4-1-20250805`, `claude-opus-4-20250514`, `claude-sonnet-4-20250514`, `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## API parameter changes

- `temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` and return a 400 error; omit them and steer behavior through prompting.
- Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on current models; use adaptive thinking steered by `effort`.

## Tokenizer note

Models since Opus 4.7 use a newer tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic work, most workloads:** `claude-opus-5-5`
- **Hardest reasoning / long-horizon agents:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- In Claude Code, `ultrathink` runs at xhigh effort on Opus 5.5, Sonnet 5.5, Haiku 5.5, and Fable 5.1 via Anthropic's API.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
