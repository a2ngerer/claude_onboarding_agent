---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-12
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.2, Opus 5.5, Sonnet 5.5, and Haiku 5.5. Fable sits above Opus as the highest-capability generally available tier. Start with Opus 5.5 for most workloads; move to Fable 5.2 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best speed/intelligence balance for most tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium         | High-volume, latency-sensitive work, classification, subagents |

All four use adaptive thinking (always on for Fable and Opus). Batch API requests are 50% off. Cache reads cost 10% of base input (5% on Opus 5.5 and Sonnet 5.5, 2.5% on Fable 5.2).

`claude-mythos-5-2` is the Fable-class model without dual-use safety measures. It is limited-availability (verified organizations only) and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases resolve to the current recommended model for that tier and move when Anthropic promotes a new default. In Claude Code, saved Fable 5.1 selections moved to `fable` (now 5.2); use `/model claude-fable-5-1` to switch back.

## ID pinning behavior

Every dateless model ID (4.6 generation onward) is a pinned snapshot, not a moving pointer. Use them for stability without memorizing a full dated ID. Only the short aliases move.

## Previous generation (still available)

`claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001`. Prefer the 5.5 IDs for new work.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1` — retired on the Claude API (may remain on some cloud partners)
- Opus 4.8 fast mode — deprecated 2026-10-30, removed 2026-11-30 in Claude Code; migrate to Opus 5.5
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

Planned retirement: not sooner than 2027-09-22 (Opus 5.5), 2027-09-28 (Sonnet 5.5), 2027-10-07 (Haiku 5.5), 2027-11-09 (Fable 5.2).

## Tokenizer note

Opus 4.7 and later (including the whole 5.x family) use a tokenizer that produces roughly 30–35% more tokens for the same text than earlier models. Factor this into cost estimates when migrating from older models.

## Defaults

- **Most workloads and agentic coding:** `claude-opus-5-5`
- **Balanced speed and cost:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Set `effort` explicitly when the default does not fit; at `max` effort Opus 5.5, Sonnet 5.5, and Fable 5.2 can spend the whole 128k output budget on thinking.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
