---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-24
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current generation as of `last_updated`: Fable 5.2, Opus 5.5, Sonnet 5.5, and Haiku 5.5, all with a 1M-token context window and 128k max output. Fable sits above Opus as the highest-capability generally available tier. Default to the IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; adaptive thinking always on |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k); $0.50 / $2.50 above | Fast, cheap, high-volume tasks, classification, routing, subagents |

`claude-mythos-5-2` is the Fable 5.2 generation without dual-use safety measures. It is limited-availability (Cyber Verification Program) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including dateless IDs (used from the 4.6 generation on). Aliases in Claude Code still move when defaults are promoted; use the full ID for reproducibility across promotions.

## Pricing notes

- Batch API: 50% off input and output. Prompt-cache reads cost 0.1x base input (0.05x on Opus 5.5 and Sonnet 5.5, 0.025x on Fable 5.2).
- Haiku 5.5 is the only current model priced by prompt length (higher rates above 100k input tokens); the others bill the full 1M window at standard rates.
- Fast mode (up to 2.5x output speed, premium price) is available for Fable 5.2, Opus 5.5, and Opus 5.

## Older models still available

Prefer the 5.5 IDs for new work. Still available: `claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5`.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` — retired (remain only on some partner clouds)
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

Current models list retirement "not sooner than" dates from Sep 2027 (Opus 5.5) to Nov 2027 (Fable 5.2).

## Tokenizer note

Claude 4.7 and later models use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from 4.6 and earlier.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic coding / deep reasoning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Adaptive thinking is steered by `effort`; extended thinking (`budget_tokens`) is not accepted on newer models.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
