---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-06-09
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 2
---

## Latest family

Claude 4.x is the current family as of `last_updated`. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias              | Context | Typical use case |
|--------|-----------------------------|--------------------|---------|------------------|
| Opus   | `claude-opus-4-8`           | claude-opus-4-8    | 1M      | Most capable — complex reasoning, long-horizon agentic coding, high-autonomy work |
| Sonnet | `claude-sonnet-4-6`         | claude-sonnet-4-6  | 1M      | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | claude-haiku-4-5   | 200k    | Fast, cheap, high-volume tasks and subagents |

All IDs starting with the 4.6 generation are pinned snapshots (dateless format). Aliases for these models equal the ID — they are not rolling pointers. Only pre-4.6 dated IDs (e.g. `claude-haiku-4-5-20251001`) have a shorter alias that may roll.

## Deprecated

Avoid in new code — these point to weaker models or have upcoming retirement dates.

- `claude-opus-4-1-20250805` — retires 2026-08-05; migrate to `claude-opus-4-8`
- `claude-sonnet-4-20250514` — retires 2026-06-15; migrate to `claude-sonnet-4-6`
- `claude-opus-4-20250514` — retires 2026-06-15; migrate to `claude-opus-4-8`
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
- **Deep reasoning / agentic planning:** `claude-opus-4-8`
- **High-throughput subagents / background tasks:** `claude-haiku-4-5-20251001`
- **Building AI apps on the Anthropic SDK:** start with `claude-sonnet-4-6`; upgrade to Opus 4.8 only when quality demands it.

## Tips

- For pre-4.6 models, prefer the **dated ID** over an alias in production — the shorter alias may roll to a newer snapshot silently.
- When migrating between versions, re-run your eval suite; prompts tuned for one model family may need light adjustment.
- On `claude-opus-4-8`, the `effort` parameter defaults to `high` on all surfaces (API and Claude Code). Set it explicitly to `medium` or `low` to reduce cost on lighter workloads.
- Opus 4.8 and Sonnet 4.6 support up to 300k output tokens via the `output-300k-2026-03-24` beta header on the Message Batches API.
