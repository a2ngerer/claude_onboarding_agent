---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-28
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current generation as of `last_updated`: Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5. Start with Opus 5.5 for most workloads; use Fable 5.2 for demanding reasoning and long-horizon agentic work. Default to the latest IDs below unless a project has pinned an older version.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | Maximum capability, long-horizon agentic work; default effort `high` |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | Long-running agentic coding and knowledge work; default effort `medium` |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | Balanced default — speed plus intelligence for most tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | $0.10 / $0.50 (≤100k prompt); $0.50 / $2.50 above | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-2` has the same pricing as Fable 5.2 but limited availability (verification programs such as the Cyber Verification Program). Not for general use. All 5.5-generation models use adaptive thinking.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier and move when Anthropic promotes a new default. On some third-party providers an alias may resolve to an older model (for example `sonnet` on Bedrock stays at Sonnet 4.5), so pin full IDs there.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation. Use them for stability; use aliases only if you want to follow promotions.

## Older models

Prefer the 5.5 generation for new work. Still available: Fable 5.1 / 5, Opus 5 / 4.8 / 4.7 / 4.6 / 4.5, Sonnet 5 / 4.6 / 4.5, Haiku 4.5 (`claude-haiku-4-5-20251001`, 200k context, $1 / $5). Retired (except on some cloud platforms): Opus 4.1, Opus 4, Sonnet 4. Retirement floors: Fable 5.2 not before 2027-11-09, Opus 5.5 2027-09-22, Sonnet 5.5 2027-09-28, Haiku 5.5 2027-10-07. Do not use these older IDs in new code or configs:

- `claude-sonnet-4-0`, `claude-opus-4-0`, `claude-opus-4-1`
- `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
- `claude-2.1`, `claude-2.0`, `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (including all of the 5.x family) use a newer tokenizer that produces roughly 30% more tokens for the same text than Sonnet 4.6 and earlier. Factor this into cost estimates when migrating.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5-5`
- **Deep reasoning / agentic planning:** `claude-opus-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs (`claude-opus-5-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Prompt-cache reads are discounted heavily on the newest models (0.025x base on Fable 5.2, 0.05x on Opus 5.5 / Sonnet 5.5); Batch API is 50% off.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
