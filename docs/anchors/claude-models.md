---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-15
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current generation as of `last_updated`: Fable 5.2, Opus 5.5, Sonnet 5.5, and Haiku 5.5, all with a 1M-token context window and 128k max output. Fable sits above Opus as the highest-capability generally available tier. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Demanding reasoning and long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | Fast, cheap, high-volume tasks (classification, extraction, routing) and subagents |

`claude-mythos-5-2` has the same pricing as Fable 5.2 but is limited-availability (Cyber Verification Program). It is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default. Claude Code migrates saved `claude-fable-5-1` picks to the `fable` alias.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Aliases are the only moving pointers; use the full ID when you need reproducibility across alias promotions.

## Older models still active

`claude-fable-5-1`, `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-sonnet-5`, `claude-sonnet-4-6`, and `claude-haiku-4-5-20251001` remain available. Prefer the 5.5 IDs for new work.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — deprecated; **retires 2026-11-30**; replace with `claude-sonnet-5-5`
- `claude-opus-4-5-20251101` — active, retirement not sooner than 2026-11-24
- `claude-haiku-4-5-20251001` — active, retirement not sooner than 2026-10-15; plan migration to `claude-haiku-5-5`
- `claude-opus-4-1-20250805` — retired 2026-08-05
- `claude-opus-4-20250514`, `claude-sonnet-4-20250514` — retired 2026-06-15
- `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022` — retired 2026-02-19
- `claude-3-haiku-20240307` — retired 2026-04-20
- `claude-3-opus-20240229`, `claude-3-5-sonnet-*`, `claude-3-sonnet-20240229`, `claude-2.0`, `claude-2.1`, `claude-instant-*` — retired
- `claude-mythos-preview` — deprecated 2026-06-09

## API parameter note

`temperature`, `top_p`, and `top_k` were removed in API version `2026-10-21` (400 error). Omit them and steer behavior through prompting; extended thinking with `budget_tokens` is not accepted on current models — use adaptive thinking plus `effort`.

## Defaults

- **Everyday tasks and agentic coding:** `claude-sonnet-5-5`
- **Long-running agentic work / deep analysis:** `claude-opus-5-5` (start here when unsure)
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs in production for stability; aliases move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Batch API requests are 50% off; prompt-cache reads cost a fraction of base input price (see the pricing page).
