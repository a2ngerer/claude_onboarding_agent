---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-06
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason. The docs suggest starting with Opus 5.5 for most workloads and moving to Fable 5.1 when evals at higher effort on Opus 5.5 still fall short.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

`claude-mythos-5-1` is the Fable-class model without dual-use safety measures. It is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Aliases in Claude Code still move; if you want reproducibility across alias promotions, use the full model ID directly.

## Legacy and deprecated

Do not use deprecated or retired IDs in new code or configs. Retirement dates apply to Anthropic-operated platforms; Bedrock and Google-managed Vertex set their own.

- `claude-sonnet-4-5-20250929` — **deprecated; retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- `claude-haiku-4-5-20251001` — legacy, not sooner than 2026-10-15
- `claude-opus-4-5-20251101` — legacy, not sooner than 2026-11-24
- `claude-opus-4-6`, `claude-opus-4-7`, `claude-opus-4-8`, `claude-sonnet-4-6` — legacy, still available
- `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5` — legacy, still available
- `claude-mythos-preview` — deprecated 2026-06-09
- Retired (requests fail): `claude-opus-4-1-20250805`, `claude-opus-4-20250514`, `claude-sonnet-4-20250514`, `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`, `claude-3-haiku-20240307`, `claude-3-5-sonnet-*`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-2.x`, `claude-instant-*`

Claude Code: fast mode for Opus 4.8 is deprecated and will be removed on 2026-11-30; migrate to Opus 5.5.

## API parameter note

`temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` (400 error). Omit them and steer behavior via prompting and `effort`. Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on newer models; use adaptive thinking.

## Tokenizer note

Models from Opus 4.7 onward use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / hard reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full model IDs for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Batch API requests are 50% off; prompt-cache reads cost a fraction of base input price (see the pricing page).
