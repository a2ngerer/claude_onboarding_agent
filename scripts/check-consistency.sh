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

mapfile -t commands < <(jq -r '.commands[].name' "$MANIFEST")

failed=0

for cmd in "${commands[@]}"; do
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

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "Consistency checks passed."
