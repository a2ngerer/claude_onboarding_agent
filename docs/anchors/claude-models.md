---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-08-10
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Claude Opus 5 replaced Claude Opus 4.8 as the recommended default for complex agentic coding and enterprise work on 2026-07-24; Claude Sonnet 5 replaced Claude Sonnet 4.6 as the balanced default on 2026-06-30. Fable 5 remains the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

Fable 5 and Mythos 5 access was briefly suspended worldwide (2026-06-13) under a US export-control order, then restored (2026-07-18) as a permanent Max/Team Premium subscription benefit at 50% of normal usage limits. This affects claude.ai/Claude Code subscription access, not API-key usage.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5`      | `fable` | 1M      | 128k       | $10 / $50                 | Maximum capability, long-running agents, always-on adaptive thinking |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding, enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10 through 2026-08-31, then $3 / $15 | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5` shares Fable 5's specs and pricing but is limited-availability (invitation-only, Project Glasswing) for defensive cybersecurity workflows. `claude-mythos-preview` is a separate invitation-only preview ID in the same program.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Since the 4.6 generation, undated model IDs (e.g. `claude-opus-5`) are pinned snapshots, not moving pointers. Use them when you want stability without memorizing a full dated ID. Aliases still move; if you want reproducibility across alias promotions, use the undated or dated ID directly.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. Entries marked with a retirement date have already stopped working on the Claude API (some remain served on Bedrock/Google Cloud past that date).

- `claude-opus-4-1` — **retired 2026-08-05**
- `claude-opus-4-0` / `claude-sonnet-4-0` — **retired 2026-06-15**
- `claude-haiku-3-5` — retired
- `claude-opus-4-8` — legacy, still available (superseded by `claude-opus-5`)
- `claude-opus-4-7` — legacy, still available
- `claude-opus-4-6` — legacy, still available
- `claude-sonnet-4-6` — legacy, still available (superseded by `claude-sonnet-5`)
- `claude-sonnet-4-5-20250929` — legacy, still available
- `claude-opus-4-5-20251101` — legacy, still available
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

Fable 5, Mythos 5, Mythos Preview, Sonnet 5, and Opus 4.7+ (including Opus 5) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier models. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use undated IDs (`claude-opus-5`) for production stability; they are pinned snapshots since the 4.6 generation. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Sonnet 5's introductory pricing ($2/$10 per MTok) reverts to standard ($3/$15) on 2026-09-01 — don't hardcode the promotional rate in cost estimates that outlive that date.
