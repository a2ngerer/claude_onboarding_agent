---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-16
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.x is the current family as of `last_updated`. Start with Opus 5.5 for most workloads; use Fable 5.2 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | high   | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high   | Best speed/intelligence balance; most coding tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium | Fast, cheap, high-volume tasks, classification, subagents |

All four use adaptive thinking, have a June 2026 knowledge cutoff, and have a retirement commitment no sooner than Sep–Nov 2027. Prompt-cache reads cost 10% of input price (2.5% on Fable, 5% on Opus 5.5 and Sonnet 5.5). Batch API is 50% off.

`claude-mythos-5-2` has the same price as Fable 5.2 but is limited-availability (verified organizations only, e.g. the Cyber Verification Program) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default (Claude Code moved saved Fable 5.1 selections to `fable`, i.e. Fable 5.2, in v2.1.321).

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Use them for stability; use aliases only when you want to follow promotions.

## Older models still available

Prefer the 5.5 IDs above. Older models remain callable but are not recommended for new work:

- Fable: `claude-fable-5-1`, `claude-fable-5` ($10 / $50)
- Opus: `claude-opus-5`, `claude-opus-4-8`, `-4-7`, `-4-6` ($5 / $25, 1M); `claude-opus-4-5` (200k)
- Sonnet: `claude-sonnet-5` ($2 / $10), `claude-sonnet-4-6` ($3 / $15, 1M), `claude-sonnet-4-5` (200k)
- Haiku: `claude-haiku-4-5-20251001` ($1 / $5, 200k)
- Mythos 5, 5.1, 5.2 — limited availability

Opus 4.8 fast mode is deprecated (Oct 30, 2026) and is removed on Nov 30, 2026; migrate to Opus 5.5 to keep the speedup.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0` — retired on the Claude API (may persist on Bedrock / Google Cloud)
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on models after Opus 4.6 / Sonnet 4.6; use adaptive thinking steered by `effort`.

## Tokenizer note

Opus 4.7 and later (including all 5.x models) use a tokenizer that produces roughly 30% more tokens for the same text than pre-4.7 models. Factor this into cost estimates when migrating from older models.

## Defaults

- **General starting point and agentic coding:** `claude-opus-5-5`
- **Everyday coding / speed-sensitive work:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Claude Code assumes a 1M context window for unrecognized model IDs; set `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` to keep 200k.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
