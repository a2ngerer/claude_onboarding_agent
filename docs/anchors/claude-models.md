---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-19
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current generation as of `last_updated`: Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5. All four have a 1M-token context window, 128k max output, and adaptive thinking. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias   | Default effort | Input / Output (per MTok) | Typical use case |
|--------|---------------------|---------|----------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable` | high           | $8 / $40                  | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`  | medium         | $4 / $20                  | Long-running agentic coding and knowledge work; recommended start for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet`| high           | $2 / $10                  | Best speed/intelligence balance — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku` | medium         | from $0.10 / $0.50        | Fast, cheap, high-volume tasks, classification, routing, subagents |

Claude Mythos 5.2 is the Fable 5.2 counterpart without dual-use safety measures. It is limited-availability (Cyber Verification Program) and not for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. Use the dateless ID for stability; aliases may move. Verify exact IDs against the models page when in doubt.

## Thinking and effort

Adaptive thinking is the norm on current models; manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is deprecated on Opus 4.6 / Sonnet 4.6 and not accepted on later models. Steer depth with the `effort` parameter. Very high effort on Opus 5.5 can exhaust the token budget before producing output — leave headroom in `max_tokens`.

## Older models (still available, not for new work)

- 5.x: `claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`
- 4.x (1M context): `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-4-6`
- 4.x (200k context): `claude-opus-4-5`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001`

## Retired / deprecated

Do not use these IDs in new code or configs. Opus 4, Opus 4.1, and Sonnet 4 are retired on Anthropic-operated platforms (some partner clouds still serve them). Earlier generations (`claude-3-*`, `claude-2.*`, `claude-instant-1.2`) are deprecated or retired. Check the model-deprecations page for exact dates.

Current retirement commitments (not sooner than): Fable 5.2 2027-11-09, Opus 5.5 2027-09-22, Sonnet 5.5 2027-09-28, Haiku 5.5 2027-10-07.

## Tokenizer note

Models since Opus 4.7 use a tokenizer that yields roughly 30% more tokens for the same text than earlier ones (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads, agentic coding, long-running tasks:** `claude-opus-5-5`
- **Balanced everyday coding / speed-sensitive work:** `claude-sonnet-5-5`
- **Hardest reasoning, long-horizon agents:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs for production stability; use aliases only when you want to follow promotions.
- Batch API requests are 50% off; prompt-cache reads cost a fraction of base input price.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
