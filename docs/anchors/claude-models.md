---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-05
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family. Default to the IDs below unless a project has pinned an older version. Model IDs from the 4.6 generation onward are dateless pinned snapshots — not evergreen pointers.

## Model IDs

| Tier   | Model ID                    | Alias                     | Context | Max output | Typical use case |
|--------|-----------------------------|---------------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-8`           | `claude-opus-4-8`         | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | `claude-sonnet-4-6`       | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`        | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

## Effort (Opus 4.8)

Opus 4.8 defaults to `effort: high` on all surfaces including the API and Claude Code. Set it explicitly to change level. Level `xhigh` is exclusive to Opus 4.8 and enables deeper reasoning passes at extra cost.

## Deprecated — retire June 15 2026

These IDs are announced for retirement on June 15, 2026. Migrate before that date.

- `claude-sonnet-4-20250514` → replace with `claude-sonnet-4-6`
- `claude-opus-4-20250514` → replace with `claude-opus-4-8`

## Deprecated — do not use in new code

Older IDs that point to weaker models and will stop working on their retirement dates:

- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus 4.8 only when quality demands it.

## Tips

- Prefer the **exact model ID** over an alias in production — 4.x aliases match the ID, but older aliases can move silently.
- Opus 4.8 and Sonnet 4.6 share a 1M-token context window; budget file reads accordingly.
- When migrating between model families, re-run your eval suite; prompts tuned for one family may need adjustment.
- Use `claude-haiku-4-5-20251001` (alias `claude-haiku-4-5`) in the `model:` frontmatter of read-only subagents to reduce cost.
