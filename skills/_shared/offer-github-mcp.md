# Offer GitHub MCP (shared procedure)

> Consumed by `coding-setup` and `web-development-setup` at their "Offer GitHub MCP" step. Do not invoke directly.

Canonical wrapper around `skills/_shared/offer-mcp.md` for the GitHub MCP
server. Every consumer skill points here so the trigger condition, install
command, auth detail, and pointer link stay identical across the plugin.

Slug, install command, and pointer link MUST match `docs/anchors/mcp-servers.md`.
Do not override them from the consumer skill.

## Contract

The calling skill sets this input (inline in its own prose, not as a
structured argument) before reading this file:

| Parameter | Example | Purpose |
|---|---|---|
| `skill_slug` | `coding-setup` | Owning skill, used for state logging in the underlying `offer-mcp.md` |

## Step 1: Delegate to `offer-mcp.md`

The opt-in question — effectively "Install the GitHub MCP?" — is rendered by
`offer-mcp.md`'s Step 3 prompt template using the parameters below. Read
`skills/_shared/offer-mcp.md` and follow it with these parameters:

- `mcp_slug`: `github`
- `trigger_condition`: project is git-initialized AND has a GitHub remote.
  Check via Bash:
  `git remote -v 2>/dev/null | grep -q 'github.com' && echo YES || echo NO`
  If `NO`, skip this step entirely — no prompt, no CLAUDE.md change.
- `capability_line`: "Access GitHub issues, PRs, and reviews directly via the
  GitHub API instead of shelling out to `gh`."
- `install_command`: `claude mcp add github npx -- -y @modelcontextprotocol/server-github`
- `auth_type`: `api_token`
- `auth_detail`: `GITHUB_PERSONAL_ACCESS_TOKEN` (generate at
  https://github.com/settings/tokens — scope `repo` for private repos, else
  `public_repo`)
- `pointer_link`: `https://github.com/modelcontextprotocol/servers/tree/main/src/github`

## Step 2: Record state

`offer-mcp.md` sets `github_installed` (and, on `later`, `github_deferred`)
in the calling skill's state. Reuse those variables in the CLAUDE.md
`## Configured MCP servers` subsection (Step 5 of `offer-mcp.md`) and in the
completion summary. This helper adds no additional state.
