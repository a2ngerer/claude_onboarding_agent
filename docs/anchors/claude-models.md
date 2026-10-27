---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-27
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated` (Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5). Fable sits above Opus as the highest-capability tier. Start with Opus 5.5 for most workloads; use Fable 5.1 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high   | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high   | Best speed/intelligence balance — everyday coding |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k; $0.50 / $2.50 above) | medium | High-volume, latency-sensitive tasks, classification, routing, subagents |

All four use adaptive thinking (always on for Fable and Opus). `claude-mythos-5-1` is the Fable-class model without dual-use safety measures; it is limited-availability and not recommended for general use. Batch API requests are 50% off; on the Message Batches API the 5.5 models support up to 300k output tokens with the `output-300k-2026-03-24` beta header.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). In Claude Code, the `fable` alias retries once on the previous Fable model if the newest one is not available to your organization.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Aliases in Claude Code can move when Anthropic promotes a new default; use the full ID when you need reproducibility.

## Legacy (still available)

`claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001`. Prefer the 5.5 IDs for new work.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — retired (remain only on some partner platforms)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Retirement commitments for the 5.5 models: not sooner than 2027-09-01 (Fable 5.1), 2027-09-22 (Opus 5.5), 2027-09-28 (Sonnet 5.5), 2027-10-07 (Haiku 5.5).

## Tokenizer note

Models since Opus 4.7 use a tokenizer that produces roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from older models. Extended thinking (`thinking.type: "enabled"` with `budget_tokens`) is not accepted on later models; use adaptive thinking with `effort`.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / agentic planning (recommended starting point for hard work):** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Set `effort` explicitly when you need a level other than the model default; `ultrathink` in Claude Code runs a single turn at xhigh effort on all four 5.5-generation models.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment. See the Opus 5.5 migration guide if coming from Opus 5 or earlier.
