---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-22
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Fable 5.2 sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason. All current models support text and image input, tool use, and adaptive thinking.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; start here for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best balance of speed and intelligence — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | $0.10 / $0.50 (prompts ≤100k); $0.50 / $2.50 above | medium | High-volume, latency-sensitive tasks: classification, extraction, routing, subagents |

`claude-mythos-5-2` is the Fable-class model without dual-use safety measures. It is limited-availability (verified organizations only) and not recommended for general use.

Earlier 5.x snapshots (Fable 5.1 / 5, Opus 5, Sonnet 5) remain available. Earlier Fable models cost $10 / $50.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). In Claude Code, aliases resolve to the current recommended snapshot for that tier and move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). On the API, the alias row repeats the dateless ID. Use the ID directly when you need reproducibility across Claude Code alias promotions.

## Deprecated / retiring soon

Do not use these IDs in new code or configs. See the model-deprecations page for dates; current models are committed to stay available until at least Sep–Nov 2027.

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` — retired (still served only on some partner clouds)
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5` — legacy, still available
- `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001` — legacy, still available
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is deprecated on Opus 4.6 / Sonnet 4.6 and rejected on later models — use adaptive thinking plus `effort`.

## Tokenizer note

Claude 4.7 and later models use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Deep reasoning / long-running agentic work:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Prompt-cache reads are cheap on the newest models (0.025x base input on Fable 5.2, 0.05x on Opus 5.5 / Sonnet 5.5, 0.1x elsewhere). Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
