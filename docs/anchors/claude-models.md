---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-07
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Claude Fable 5.1 sits above Opus 5 as the model for demanding reasoning and long-horizon agentic work; Opus 5 is Anthropic's recommended starting point for most workloads. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work, adaptive thinking (always on) |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; recommended default for most workloads |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Best combination of speed and intelligence — Claude Code's coding default |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fastest, near-frontier intelligence; cheap high-volume tasks and subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy (still available, not deprecated)

Superseded by the models above but still served: `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

## Deprecated / retired

Do not use these IDs in new code or configs. Retired on Anthropic-operated platforms (Claude API, Claude Platform on AWS, Microsoft Foundry); Amazon Bedrock and Google Cloud set their own retirement schedules and may still serve some of them.

- `claude-opus-4-1` — retired 2026-08-05
- `claude-opus-4-0` / `claude-sonnet-4-0` — retired 2026-06-15
- `claude-haiku-3-5` — retired on Anthropic-operated platforms
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Fable 5.1, Fable 5, Mythos 5 / 5.1, Opus 5, Opus 4.7+, and Sonnet 5 use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier models. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / most workloads / agentic planning:** `claude-opus-5`
- **Maximum capability / longest-horizon reasoning:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Claude Sonnet 5's $2/$10 launch pricing is now standard — the previously scheduled increase to $3/$15 on 2026-09-01 was cancelled.
- Prompt-cache reads are priced at 0.1x base input on most tiers, but only 0.025x on Fable 5.1 and Mythos 5.1.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
