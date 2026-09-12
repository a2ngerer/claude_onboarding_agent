---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-09-12
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

The Claude 5 generation is current as of `last_updated`: Claude Fable 5.1 is the highest-capability model, Claude Opus 5 is recommended for most agentic coding and enterprise work, Claude Sonnet 5 gives the best combination of speed and intelligence, and Claude Haiku 4.5 remains the fast/cheap tier. Default to the latest IDs listed below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID              | Alias   | Context | Max output | Input / Output (per MTok) | Typical use case |
|--------|-----------------------|---------|---------|------------|---------------------------|------------------|
| Fable  | `claude-fable-5-1`    | `fable` | 1M      | 128k       | $10 / $50                 | Demanding reasoning, long-horizon agentic work; adaptive thinking always on |
| Opus   | `claude-opus-5`       | `opus`  | 1M      | 128k       | $5 / $25                  | Complex agentic coding and enterprise work; defaults to high effort |
| Sonnet | `claude-sonnet-5`     | `sonnet`| 1M      | 128k       | $2 / $10                  | Balanced default — most coding and general tasks |
| Haiku  | `claude-haiku-4-5-20251001` | `haiku` | 200k | 64k    | $1 / $5                   | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-1` is the same model as Fable 5.1 but without dual-use safety measures. It is invitation-only and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases always point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used from the 4.6 generation on (e.g. `claude-opus-5`, `claude-sonnet-5`, `claude-fable-5-1`). For models before the 4.6 generation, the alias is a convenience pointer that resolves to a dated ID. Dateless IDs from 4.6 onward are their own pinned snapshot; the alias row just repeats them.

## Legacy (still available, no longer the default)

`claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5` — all still served, but superseded as recommended defaults by the Claude 5 generation above.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-0` — retired
- `claude-opus-4-0` — retired
- `claude-opus-4-1` — retired, except on Bedrock and Google Cloud
- `claude-opus-4` — retired, except on Google Cloud
- `claude-sonnet-4` — retired, except on Bedrock and Google Cloud
- `claude-haiku-3-5` — retired, except on Bedrock and Google Cloud
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`
- `claude-3-5-sonnet-20240620`
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-2.1`
- `claude-2.0`
- `claude-instant-1.2`

## Tokenizer note

Claude 4.7 and later models (and Mythos Preview) use a newer tokenizer that produces roughly 30% more tokens for the same text. Claude Sonnet 4.6 and earlier models use the previous tokenizer. Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and agentic coding (Claude Code default):** `claude-sonnet-5`
- **Deep reasoning / agentic planning / complex coding:** `claude-opus-5`
- **Maximum capability:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-4-5-20251001`

## Tips

- Use dateless IDs (`claude-opus-5`, `claude-sonnet-5`) for production stability; they are pinned snapshots. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
