---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-30
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.1 sits above Opus as the highest-capability generally available model. Anthropic recommends starting with Opus 5.5 for most workloads and moving to Fable 5.1 when evals at higher effort still fall short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`          | `fable`  | 1M      | 128k       | $10 / $50                 | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`           | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5`         | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence for most coding tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku`  | 200k    | 64k        | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` is the Fable 5.1 tier without dual-use safety measures. It is limited-availability (Project Glasswing), invitation-only, and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases in Claude Code still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy / deprecated

Prefer the current IDs above in new code or configs. Retired models fail on Anthropic-operated platforms (Bedrock and Google Cloud set their own dates).

- Legacy, still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-5`, `claude-sonnet-4-6`
- `claude-sonnet-4-5-20250929` — retires not sooner than 2026-09-29 (imminent)
- `claude-opus-4-5-20251101` — retires not sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — active; retires not sooner than 2026-10-15
- `claude-mythos-preview` — deprecated 2026-06-09
- Retired: `claude-opus-4-1-20250805` (2026-08-05), `claude-opus-4-20250514` and `claude-sonnet-4-20250514` (2026-06-15), `claude-3-haiku-20240307`, `claude-3-5-haiku-20241022`, `claude-3-7-sonnet-20250219`, `claude-3-5-sonnet-*`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-2.x`, `claude-instant-1.x`

## Tokenizer note

Claude 4.7+ models (Fable, Mythos, Opus 4.7+, Sonnet 5.x) use a new tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads (Anthropic's starting point):** `claude-opus-5-5`
- **Everyday tasks and fast agentic coding:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Claude 4.7+ models return a 400 for non-default `temperature`, `top_p`, or `top_k`; omit them and steer via prompting.
- Cache reads cost 10% of input price (5% on Opus 5.5, 2.5% on Fable 5.1); the Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
