---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-05-08
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias             | Context | Max output | Typical use case |
|--------|-----------------------------|-------------------|---------|------------|------------------|
| Opus   | `claude-opus-4-7`           | claude-opus-4-7   | 1M      | 128k       | Hardest reasoning, deep code analysis, agentic workflows |
| Sonnet | `claude-sonnet-4-6`         | claude-sonnet-4-6 | 1M      | 64k        | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | claude-haiku-4-5  | 200k    | 64k        | Fast, cheap, high-volume tasks and subagents |

**Opus 4.7 tokenizer:** A new tokenizer raises token counts ~1.0–1.35× vs. older models; pricing is unchanged. The 1M context window is ~555k words.

**Knowledge cutoffs:** Opus 4.7 = Jan 2026 (reliable) / Jan 2026 (training). Sonnet 4.6 = Aug 2025 / Jan 2026. Haiku 4.5 = Feb 2025 / Jul 2025.

## Deprecated

Do not use these IDs in new code or configs.

**Retiring June 15, 2026:**
- `claude-sonnet-4-20250514` (alias: `claude-sonnet-4-0`)
- `claude-opus-4-20250514` (alias: `claude-opus-4-0`)

**Older — avoid in new work:**
- `claude-3-opus-20240229`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-3-haiku-20240307`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

Legacy 4.x models still available (Opus 4.6, Sonnet 4.5, Opus 4.5, Opus 4.1) but not recommended for new projects — migrate to the latest tier.

## Defaults

- **General coding (Claude Code default):** `claude-sonnet-4-6`
- **Deep reasoning / agentic planning:** `claude-opus-4-7`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus only when quality demands it.

## Tips

- In the 4.x generation, dateless IDs (`claude-sonnet-4-6`) are pinned snapshots, not evergreen pointers. Prefer them over aliases in production.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- Opus 4.7's new tokenizer raises token counts ~1.0–1.35×; re-check token budgets and context usage when migrating from Opus 4.6.
