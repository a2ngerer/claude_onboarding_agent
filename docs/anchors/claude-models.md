---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-10-09
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.1, Opus 5.5, Sonnet 5.5, and Haiku 5.5. The Fable tier sits above Opus as the highest-capability generally available model. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

All current models share a 1M-token context window, 128k max output, adaptive thinking, and a June 2026 knowledge cutoff.

| Tier   | Model ID            | Alias    | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; the general starting point |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | $2 / $10                  | high           | Balanced default — speed plus intelligence |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | $0.10 / $0.50 (prompts ≤100k); $0.50 / $2.50 (>100k) | medium | High-volume, latency-sensitive work: classification, extraction, routing, subagents |

Claude Mythos 5.1 is the Fable 5.1 counterpart without dual-use safety measures. It is limited-availability (Cyber Verification Program) and not recommended for general use.

Prompt-cache reads cost 0.1x base input, except 0.025x on Fable 5.1 and 0.05x on Opus 5.5 / Sonnet 5.5. Batch API requests are 50% off.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases in Claude Code always point to the current recommended model for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Use them for stability without memorizing a full dated ID. Only Claude Code aliases move; the dateless API IDs do not.

## Retirement

Anthropic commits to not retiring the current models before: Fable 5.1 — 2027-09-01, Opus 5.5 — 2027-09-22, Sonnet 5.5 — 2027-09-28, Haiku 5.5 — 2027-10-07.

## Legacy (still available)

Fine for pinned projects; prefer the 5.5 IDs for new work.

- `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`
- `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001`

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — retired on the Claude API (may remain on Bedrock / Google Cloud)
- `claude-sonnet-4-5` — deprecated
- `claude-3-5-haiku-20241022` — retired on the Claude API
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (including all 5.x) use a newer tokenizer that produces roughly 30% more tokens for the same text. Factor this into cost estimates when migrating from Sonnet 4.6 or earlier.

## Defaults

- **General starting point and long-running agentic coding:** `claude-opus-5-5`
- **Everyday tasks and fast agentic coding:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Claude Code aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Extended thinking (`thinking.type: "enabled"` with `budget_tokens`) is not accepted on later models; use adaptive thinking steered by `effort`.
- Opus 4.7+ and Fable use a 1M context window by default on Bedrock, Vertex, and Foundry; `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` keeps 200K.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
