---
name: _trend-sources
description: Global trend radar for the daily anchor updater — picks up new Claude/MCP/agent patterns before they land in official docs
last_updated: 2026-04-21
version: 1
sources:
  - url: https://code.claude.com/docs/en/changelog
    rationale: Official Claude Code changelog ships near-daily versioned entries covering model rollouts, new hooks, subagent behavior, MCP fixes, and slash-command additions, so it is the earliest authoritative signal for workspace-tooling shifts.
    covers: [claude-models, claude-tools, mcp-servers, subagents]
  - url: https://simonwillison.net/tags/claude/
    rationale: Community-driven Claude tag archive with dated permalinks that surfaces third-party MCP servers, independent agent-workflow write-ups, and model comparisons days before they reach official channels.
    covers: [claude-models, claude-tools, mcp-servers, subagents]
  - url: https://obsidian.md/changelog/
    rationale: Official Obsidian release log with dated permalinks is the canonical feed for vault-layout, CLI, and plugin changes that affect knowledge-base workflows the plugin configures.
    covers: [knowledge-base]
---

## Selection notes

The Claude Code changelog and the Obsidian changelog together lock down four of five slugs with first-party permalinks, which gives the updater stable dated URLs to cite in rewrite rationales. Simon Willison's Claude tag fills the "community trends" role: it regularly covers externally released MCP servers, third-party subagent patterns, and model-behavior deltas that the two official feeds omit, and its `/YYYY/Mon/DD/slug/` URLs are also citation-stable. The triple has intentional redundancy on `claude-models`, `claude-tools`, `mcp-servers`, and `subagents` — the official feed reports what Anthropic shipped, the community feed reports what the ecosystem built on top, and the updater needs both signals to keep the anchors honest.
