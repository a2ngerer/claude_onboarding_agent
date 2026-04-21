# Offer MCP Server (shared procedure)

Shared procedure consumed by `coding-setup`, `web-development-setup`, `design-setup`, and `office-setup` when a setup skill wants to offer an MCP server registration to the user. Read this file before the first offer in a skill flow.

## Contract

The calling skill passes the following parameters (inline in its own prose, not as structured arguments):

| Parameter | Example | Purpose |
|---|---|---|
| `mcp_slug` | `github` | Identifier used in `claude mcp add <slug> ...` and in skill state as `<slug>_installed` |
| `trigger_condition` | "user's project has a GitHub remote" | Condition under which the offer is made. If false, the offer is silently skipped — NO prompt shown. |
| `capability_line` | "Access GitHub issues and PRs from Claude." | One-sentence description, adapted to detected language |
| `install_command` | `claude mcp add github npx -- -y @modelcontextprotocol/server-github` | Exact Bash command, copy-pasteable |
| `auth_type` | `api_token` or `oauth` | Drives the auth-flow note in the prompt |
| `auth_detail` | env var name (`GITHUB_PERSONAL_ACCESS_TOKEN`) or OAuth note | Inserted into the prompt |
| `pointer_link` | `https://github.com/modelcontextprotocol/servers` | Written into the CLAUDE.md pointer on yes or later |

Slugs, install commands, and pointer links MUST be sourced from `docs/anchors/mcp-servers.md`. Skills never hardcode a slug or command that conflicts with the anchor.

## Step 1: Check trigger condition

If `trigger_condition` is false, skip this procedure entirely — no prompt, no state change.

## Step 2: Check if already registered

Run via Bash: `claude mcp list 2>/dev/null | grep -q "^<mcp_slug>\b" && echo REGISTERED || echo NOT_REGISTERED`

- If `REGISTERED`: log `Skipped <mcp_slug> MCP offer (already registered)` to the skill's state and proceed to Step 5 with `<mcp_slug>_installed: true`. No prompt.
- Else: proceed to Step 3.

## Step 3: Prompt the user

Adapt the following to the detected language. Keep the install command and slug verbatim:

```
Offer: <mcp_slug> MCP server

<capability_line>

Install command: <install_command>

Auth: [for api_token]
  Set <auth_detail> in your shell profile before first use.
  See <pointer_link> for how to generate the token.

Auth: [for oauth]
  On first use of a <mcp_slug> tool, Claude Code opens a browser window for the provider's OAuth consent screen.
  The token is stored in Claude Code's credential store; this plugin never touches it.
  Granting access lets Claude read your data per the scopes shown on the consent screen — review before approving.

(yes / no / later)
```

- **yes** → Step 4 (execute).
- **no** → Record `<mcp_slug>_installed: false`. No CLAUDE.md pointer. Skip to Step 5.
- **later** → Record `<mcp_slug>_installed: false`, `<mcp_slug>_deferred: true`. Write a short deferred pointer into CLAUDE.md (see Step 5). Skip to Step 5.

## Step 4: Execute registration

Run via Bash exactly: `<install_command>`

- Exit code `0`: record `<mcp_slug>_installed: true`. Proceed to Step 5.
- Non-zero: surface the stderr verbatim to the user, warn once:
  > "Warning: Could not register <mcp_slug>. Error above. Continuing without it — you can retry manually with: <install_command>"
  Record `<mcp_slug>_installed: false`. Proceed to Step 5.

Never block the rest of the skill flow on a non-zero exit.

## Step 5: Write CLAUDE.md pointer

When the skill writes or updates its delimited CLAUDE.md section, include a `## Configured MCP servers` subsection with one bullet per offered MCP, using this exact pattern:

```
## Configured MCP servers
- <mcp_slug>: <capability_line> Auth: <auth summary>. See <pointer_link>.
```

Auth summary:
- `api_token` → `requires <auth_detail>`
- `oauth` → `OAuth via Claude Code`

If `<mcp_slug>_installed: false` AND `<mcp_slug>_deferred: true`, emit instead:
```
- <mcp_slug>: deferred — run `<install_command>` when ready. See <pointer_link>.
```

If `<mcp_slug>_installed: false` AND NOT deferred (plain "no"), do NOT emit a line for this MCP.

If no MCP in the skill's flow ended up on the list (all skipped or all plain-no), do NOT write the `## Configured MCP servers` heading at all — avoid empty sections.

## Step 6: Completion summary

Include one line per MCP the skill considered, in the skill's completion summary:

- `[ok] <mcp_slug> MCP registered` (on yes + success)
- `[warn] <mcp_slug> MCP registration failed — manual retry: <install_command>` (on yes + failure)
- `[deferred] <mcp_slug> MCP deferred — run <install_command> when ready` (on later)
- `[declined] <mcp_slug> MCP declined` (on no)
- Omit the line entirely if the trigger condition was false.

## Re-run behavior

Re-invoking the same setup skill re-runs the offer. That is intentional — re-running is the documented path to reconsider the choice. Skills MUST NOT persist a "user declined" marker that suppresses the offer permanently.
