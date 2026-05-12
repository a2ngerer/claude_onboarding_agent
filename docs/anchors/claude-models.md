---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-12
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

Starting with the 4.6 generation, model IDs use a dateless pinned-snapshot format — there are **no rolling `-latest` aliases** for Opus or Sonnet. Haiku retains a short-form alias.

| Tier   | Model ID                    | Short alias            | Context | Max output | Typical use case |
|--------|-----------------------------|------------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | (same as ID)           | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | (same as ID)           | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `claude-haiku-4-5`     | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

## Deprecated

Do not use these IDs in new code or configs.

**Retiring June 15, 2026** — migrate before the retirement date:
- `claude-sonnet-4-20250514` → migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` → migrate to `claude-opus-4-7`

**Previously deprecated** (no active retirement date announced):
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- Prefer the **full dated ID** (`claude-haiku-4-5-20251001`) over the short alias in production — short aliases move silently. Opus 4.7 and Sonnet 4.6 have no rolling alias, so both forms are equivalent for those tiers.
- Opus 4.7 uses a new tokenizer; it consumes ~1.46× more tokens per text character than Opus 4.6. Re-run evals and check costs when migrating.
- When migrating between version families, re-run your eval suite; prompts tuned for one family may need light adjustment.
