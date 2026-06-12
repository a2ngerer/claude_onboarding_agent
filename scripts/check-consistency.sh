#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/.claude-plugin/plugin.json"
README="$REPO_ROOT/README.md"
RELEASE_NOTES="$REPO_ROOT/docs/RELEASE-NOTES.md"
CLAUDE_DOC="$REPO_ROOT/CLAUDE.md"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required for consistency checks."
  exit 1
fi

mapfile -t skill_dirs < <(jq -r '.skills[]' "$MANIFEST")

failed=0

# Slash commands derive from skill directory names; the legacy commands[] field must stay gone.
if jq -e 'has("commands")' "$MANIFEST" >/dev/null 2>&1; then
  echo "ERROR: plugin.json contains the legacy commands[] field (removed from the plugin schema; commands derive from skill directory names)"
  failed=1
fi

for dir in "${skill_dirs[@]}"; do
  if [ ! -f "$REPO_ROOT/$dir/SKILL.md" ]; then
    echo "ERROR: skills[] entry $dir has no SKILL.md (entries must be directories containing SKILL.md)"
    failed=1
  fi
  cmd="$(basename "$dir")"
  if ! grep -q "\`/$cmd\`" "$README"; then
    echo "ERROR: README is missing command /$cmd"
    failed=1
  fi
done

legacy_commands=(
  "/build-knowledge-base"
  "/content-creator-setup"
)

for legacy in "${legacy_commands[@]}"; do
  if grep -q "$legacy" "$RELEASE_NOTES"; then
    echo "ERROR: release notes still contain legacy command $legacy"
    failed=1
  fi
done

if grep -q '^- `\.claude/commands/`' "$CLAUDE_DOC"; then
  echo "ERROR: CLAUDE.md still lists .claude/commands/ in key paths"
  failed=1
fi

# Check: plugin.json version must match the newest ## v... entry in RELEASE-NOTES.md
manifest_version="$(jq -r '.version' "$MANIFEST")"
newest_release_version="$(grep -m 1 '^## v' "$RELEASE_NOTES" | sed 's/^## v\([^ ]*\).*/\1/')"
if [ "$manifest_version" != "$newest_release_version" ]; then
  echo "ERROR: plugin.json version ($manifest_version) does not match newest RELEASE-NOTES.md entry (v$newest_release_version)"
  failed=1
fi

# Check: .claude-plugin/marketplace.json must exist, be valid JSON, and plugins[0].name must equal plugin.json .name
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
if [ ! -f "$MARKETPLACE" ]; then
  echo "ERROR: .claude-plugin/marketplace.json does not exist"
  failed=1
else
  if ! jq . "$MARKETPLACE" >/dev/null 2>&1; then
    echo "ERROR: .claude-plugin/marketplace.json is not valid JSON"
    failed=1
  else
    marketplace_plugin_name="$(jq -r '.plugins[0].name' "$MARKETPLACE")"
    manifest_name="$(jq -r '.name' "$MANIFEST")"
    if [ "$marketplace_plugin_name" != "$manifest_name" ]; then
      echo "ERROR: marketplace.json plugins[0].name ($marketplace_plugin_name) does not match plugin.json name ($manifest_name)"
      failed=1
    fi
  fi
fi

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "Consistency checks passed."
