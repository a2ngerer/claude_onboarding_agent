---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-31
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated` (Fable 5.1, Opus 5.5, Sonnet 5.5, Haiku 5.5). Fable sits above Opus as the highest-capability tier. Default to the latest IDs below unless a project has pinned an older version for a specific reason. Start with Opus 5.5 for most workloads; move to Fable 5.1 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short on your evals.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best balance of speed and intelligence |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium         | High-volume, latency-sensitive tasks, subagents |

Thinking is adaptive on all four (always on for Fable and Opus); manual `thinking.type: "enabled"` with `budget_tokens` is not accepted on these models. Claude Mythos 5.1 is Fable's sibling without dual-use safety measures; it is limited availability and not recommended for general use.

## Aliases

The `model:` field in Claude Code accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended model for that tier and move when Anthropic promotes a new default. On Bedrock and Vertex, `sonnet`/`opus`/`haiku` fall back to an older model when the newest is unavailable.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on. Use the dateless ID for stability; use an alias only if you want to follow promotions.

## Legacy (still available)

Fable 5 (`claude-fable-5`), Opus 5 (`claude-opus-5`), Opus 4.8 / 4.7 / 4.6 / 4.5, Sonnet 5 (`claude-sonnet-5`), Sonnet 4.6, Haiku 4.5 (`claude-haiku-4-5-20251001`). Prefer the 5.5 IDs for new work.

Retirement commitments for the current models: Fable 5.1 not before 2027-09-01, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.

## Deprecated / retired

Do not use these IDs in new code or configs.

- Opus 4.8 fast mode in Claude Code is removed 2026-11-30; migrate to Opus 5.5.
- `claude-sonnet-4-0`, `claude-opus-4-0` (retired 2026-06-15), `claude-opus-4-1` (retired 2026-08-05)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Models from Opus 4.7 onward (including all 5.x) use a tokenizer that produces roughly 30% more tokens for the same text than older models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5` (or `claude-opus-5-5` for long-running agentic work)
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs for production stability; aliases move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Prompt cache reads cost 10% of base input (5% on Opus 5.5 / Sonnet 5.5, 2.5% on Fable 5.1); Batch API is 50% off.
