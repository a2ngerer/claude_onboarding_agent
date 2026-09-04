---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-04
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.1 is the newest and highest-capability tier. Opus 5 and Sonnet 5 are now the recommended defaults for most workloads, superseding Opus 4.8 and Sonnet 4.6. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; default for most hard-reasoning tasks |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — balanced default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fastest model with near-frontier intelligence; subagent scans |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It has limited availability and is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). For the current 5.x generation the alias and the dateless Claude API ID are the same pinned snapshot; aliases move only when Anthropic promotes a new default tier.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs.

- `claude-opus-4-1` — retired on the Claude API; still available on Bedrock and Google Cloud
- `claude-opus-4-0` — retired on the Claude API; still available on Google Cloud
- `claude-sonnet-4-0` — retired on the Claude API; still available on Bedrock and Google Cloud
- `claude-haiku-3-5` — retired on the Claude API; still available on Bedrock and Google Cloud
- Legacy, still available on the Claude API: `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Retirement commitments

Anthropic-operated platforms (Claude API, Claude Platform on AWS, Microsoft Foundry) commit not to retire current models sooner than: Fable 5.1 — 2027-09-01; Opus 5 — 2027-07-24; Sonnet 5 — 2027-06-30; Haiku 4.5 — 2026-10-15. Bedrock and Google Cloud set their own retirement dates.

## Tokenizer note

Claude Opus 4.7 and later — including Fable 5.1, Mythos 5.1, Opus 5, and Sonnet 5 — use a newer tokenizer that produces roughly 30% more tokens for the same text. Sonnet 4.6 and earlier models use the previous tokenizer. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 5's introductory $2/$10-per-MTok pricing is now the permanent price — the previously scheduled 2026-09-01 increase to $3/$15 was cancelled.
- Opus 5 and Fable 5.1 (1M-context models) auto-compact around ~967K tokens, close to the context ceiling — budget for that in very-large-context agentic workflows.
