#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="claude-onboarding-agent"
REPO_URL="https://github.com/a2ngerer/claude_onboarding_agent.git"

echo "Installing Claude Onboarding Agent..."

# Create plugins directory if it does not exist
mkdir -p "$PLUGIN_DIR"

TARGET="${PLUGIN_DIR}/${PLUGIN_NAME}"

if [ -d "$TARGET" ]; then
  echo "Plugin already installed at ${TARGET}. Updating..."
  git -C "$TARGET" pull
else
  echo "Cloning into ${TARGET}..."
  git clone "$REPO_URL" "$TARGET"
fi

echo ""
echo "✓ Claude Onboarding Agent installed to ${TARGET}"
echo ""
echo "Next steps:"
echo "  Start a new Claude Code session and run: /onboarding"
echo "  Or jump directly to a setup skill:"
echo "    /coding-setup"
echo "    /build-knowledge-base"
echo "    /office-setup"
echo "    /research-setup"
echo "    /content-creator-setup"
