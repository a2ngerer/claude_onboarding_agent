---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-25
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude Fable 5.1 / Opus 5.5 / Sonnet 5 / Haiku 4.5 is the current lineup as of `last_updated`. Fable sits above Opus as the highest-capability generally available tier. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID                    | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|------------------------------|----------|---------|------------|----------------------------|-------------------|
| Fable  | `claude-fable-5-1`          | `fable`  | 1M      | 128k       | $10 / $50                  | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`           | `opus`   | 1M      | 128k       | $4 / $20                   | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5`           | `sonnet` | 1M      | 128k       | $2 / $10                   | Best balance of speed and intelligence |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku`  | 200k    | 64k        | $1 / $5                    | Fastest, near-frontier intelligence; cheap subagents |

`claude-mythos-5-1` is the same generation as Fable 5.1 but without dual-use safety measures. It ships under Project Glasswing, invitation-only, and is not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude API model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5-5`). Aliases still move; if you want reproducibility across alias promotions, use the dateless or dated ID directly.

## Retirement commitments

Anthropic commits to a minimum retirement date per model on Anthropic-operated platforms (Claude API, Claude Platform on AWS, Microsoft Foundry); Bedrock and Google Cloud set their own dates.

- Claude Fable 5.1 — not sooner than 2027-09-01
- Claude Opus 5.5 — not sooner than 2027-09-22
- Claude Sonnet 5 — not sooner than 2027-06-30
- Claude Haiku 4.5 — not sooner than 2026-10-15

**Legacy (still available, not recommended for new configs):** `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`.

**Retired on Anthropic-operated platforms** (may still work on Bedrock/Google Cloud): `claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`, `claude-haiku-3-5`, and all `claude-3-*` / `claude-2.*` / `claude-instant-*` IDs.

## Tokenizer note

Claude 4.7-generation models and later (Fable 5.x, Mythos 5.x, Opus 4.7+, Opus 5.x) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating.

## Defaults

- **Claude Code product default (interactive sessions on Pro/Team/Max/Enterprise plans):** `claude-opus-5-5` (promoted 2026-09-22)
- **Balanced default for coding and general agentic tasks:** `claude-sonnet-5`
- **Maximum capability / long-horizon reasoning:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Default effort differs by tier: Fable 5.1 and Sonnet 5 default to `high`, Opus 5.5 defaults to `medium`, Haiku 4.5 doesn't support the effort parameter. Set `effort` explicitly to override.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
