---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-09
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 / Fable 5.1 is the current family as of `last_updated`. The Fable tier sits above Opus as the highest-capability generally available model. Anthropic's guidance: start with Opus 5.5 for most workloads; move to Fable 5.1 for demanding reasoning and long-horizon agentic work, or when evals on Opus 5.5 at higher effort still fall short. Default to the latest IDs below unless a project has pinned an older version for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-1`  | `fable`  | 1M      | 128k       | $10 / $50                 | high           | Demanding reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work; best default for most workloads |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Best speed/intelligence balance — everyday coding and general tasks |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium         | Fast, cheap, high-volume work: classification, extraction, routing, subagent scans |

All four use adaptive thinking (steered by `effort`). `claude-mythos-5-1` is the Fable-class model without dual-use safety measures; it is limited-availability and not recommended for general use.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Use them for stability. Aliases still move; for reproducibility across alias promotions, use the full ID.

## Legacy (still available)

`claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101` (retires not sooner than 2026-11-24), `claude-sonnet-5`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` (retires not sooner than 2026-10-15). Prefer the 5.5 generation for new work.

## Deprecated / retired

Do not use these IDs in new code or configs.

- `claude-sonnet-4-5-20250929` — deprecated; **retires 2026-11-30** (replacement: `claude-sonnet-5-5`)
- Retired: `claude-opus-4-1-20250805` (2026-08-05), `claude-opus-4-20250514` and `claude-sonnet-4-20250514` (2026-06-15)
- Retired: `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022` (2026-02-19), `claude-3-haiku-20240307` (2026-04-20)
- Retired: `claude-3-opus-20240229`, `claude-3-5-sonnet-20240620`, `claude-3-5-sonnet-20241022`, `claude-3-sonnet-20240229`, `claude-2.0`, `claude-2.1`, `claude-instant-1.2`
- `claude-mythos-preview` — deprecated 2026-06-09
- Claude Code: Opus 4.8 fast mode is removed on 2026-11-30; migrate to Opus 5.5.

## API parameter changes

`temperature`, `top_p`, and `top_k` are removed in API version `2026-10-21` (400 error) and already rejected at non-default values on Claude 4.7+ models. Omit them and steer behavior through prompting. Extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is not accepted on later models; use adaptive thinking and `effort`.

## Tokenizer note

Models from Opus 4.7 onward use a newer tokenizer: 1M tokens is roughly 555k words (versus ~750k on earlier models). Factor this into cost estimates when migrating from older models.

## Defaults

- **Everyday tasks and most workloads:** `claude-opus-5-5` (Anthropic's recommended starting point); `claude-sonnet-5-5` where speed and cost matter
- **Maximum capability / long-horizon agentic work:** `claude-fable-5-1`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use full IDs (`claude-opus-5-5`) for production stability. Aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Batch API is 50% off; prompt-cache reads cost a fraction of base input price (see the pricing page for per-model rates).
- When migrating between models, re-run your eval suite; prompts tuned for one model family may need light adjustment.
