---
name: claude-models
description: Current Claude model IDs, aliases, context limits, and recommended defaults
last_updated: 2026-11-21
sources:
  - https://docs.claude.com/en/docs/about-claude/models
  - https://docs.claude.com/en/docs/about-claude/pricing
version: 3
---

## Latest family

Claude 5.5 is the current family as of `last_updated`: Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5. Start with Opus 5.5 for most workloads; use Fable 5.2 for demanding reasoning and long-horizon agentic work, or when Opus 5.5 at higher effort still falls short. All four have a 1M-token context window and 128k max output. Pin older versions only for a specific reason.

## Model IDs

| Tier   | Model ID            | Alias    | Context | Max output | Input / Output (per MTok) | Default effort | Typical use case |
|--------|---------------------|----------|---------|------------|---------------------------|----------------|------------------|
| Fable  | `claude-fable-5-2`  | `fable`  | 1M      | 128k       | $8 / $40                  | high           | Hardest reasoning, long-horizon agentic work |
| Opus   | `claude-opus-5-5`   | `opus`   | 1M      | 128k       | $4 / $20                  | medium         | Long-running agentic coding and knowledge work |
| Sonnet | `claude-sonnet-5-5` | `sonnet` | 1M      | 128k       | $2 / $10                  | high           | Balanced default — speed and intelligence |
| Haiku  | `claude-haiku-5-5`  | `haiku`  | 1M      | 128k       | from $0.10 / from $0.50   | medium         | Fast, cheap, high-volume tasks and subagents |

`claude-mythos-5-2` (and earlier Mythos 5.x) is limited availability, open only to organizations verified through Anthropic's Cyber Verification Program; not for general use. Earlier 5.x models (Fable 5.1, Fable 5, Opus 5, Sonnet 5) and 4.x models remain listed.

## Aliases

The `model:` field accepts short aliases (`fable`, `opus`, `sonnet`, `haiku`) plus `inherit` (take the parent agent's model). Aliases point to the current recommended snapshot for that tier — they move when Anthropic promotes a new default.

## ID pinning behavior

Every Claude model ID is a pinned snapshot, including the dateless IDs used since the 4.6 generation (e.g. `claude-opus-5-5`). Aliases move; dateless IDs do not. Use dateless IDs for reproducibility.

## Thinking

Current models use adaptive thinking, steered by `effort`. Manual extended thinking (`thinking.type: "enabled"` + `budget_tokens`) is deprecated on Opus 4.6 / Sonnet 4.6 and not accepted on later models.

## Retirement and legacy

- Opus 4.1, Opus 4, and Sonnet 4 (`claude-opus-4-1`, `claude-opus-4-0`, `claude-sonnet-4-0`) are retired on the Claude API (still on some cloud platforms) — do not use.
- Current-generation commitments: Fable 5.2 not before 2027-11-09, Opus 5.5 not before 2027-09-22, Sonnet 5.5 not before 2027-09-28, Haiku 5.5 not before 2027-10-07.
- Legacy but listed: `claude-opus-4-8`, `-4-7`, `-4-6`, `-4-5`, `claude-sonnet-4-6`, `claude-sonnet-4-5`, `claude-haiku-4-5-20251001` (200k context, 64k output, $1 / $5).
- Retired older generations: `claude-3-*`, `claude-2.*`, `claude-instant-1.2`.
- Check the model-deprecations page for exact dates before pinning anything older.

## Tokenizer note

Opus 4.7 and later use a tokenizer that yields roughly 30% more tokens for the same text than earlier models (1M tokens ≈ 555k words). Factor this into cost estimates when migrating from pre-4.7 models.

## Defaults

- **Most workloads and deep agentic coding:** `claude-opus-5-5`
- **Everyday balanced tasks:** `claude-sonnet-5-5`
- **Maximum capability:** `claude-fable-5-2`
- **Fast / cheap subagent scans:** `claude-haiku-5-5`

## Tips

- Use dateless IDs for production stability; aliases (`opus`, `sonnet`, etc.) move when defaults are promoted.
- Batch API requests are 50% off; prompt-cache reads cost a fraction of input price (see the pricing page).
- When migrating between models, re-run your eval suite; prompts tuned for one family may need light adjustment.
