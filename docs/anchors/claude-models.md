---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-04
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Start with Opus 5.5 for most workloads; use Fable 5.1 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`  | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| 1M      | 128k       | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k tokens; $0.50 / $2.50 above) | Fast, cheap, high-volume tasks, classification, routing, subagents |

Claude Mythos 5.1 is the same line as Fable 5.1 without dual-use safety measures. It has limited availability and is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Legacy / deprecated

Do not use these IDs in new code or configs.

- Legacy, still available: `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001`
- Retired: `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1`
- Fast mode on Opus 4.8 in Claude Code is deprecated and will be removed on 2026-11-30 — migrate to Opus 5.5.
- Older generations (`claude-3-*`, `claude-2.*`, `claude-instant-1.2`) are retired.

Anthropic's current retirement commitments: Fable 5.1 not before 2027-09-01, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Tokenizer note

Opus 4.7 and all later models (including the 5.x family) use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / knowledge work (Anthropic's starting point for most workloads):** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use undated IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
