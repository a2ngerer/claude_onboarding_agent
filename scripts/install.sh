#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="claude-onboarding-agent"
SKILLS_DIR="${HOME}/.claude/skills"
REPO_URL="https://github.com/a2ngerer/claude_onboarding_agent.git"

echo "Installing Claude Onboarding Agent..."

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not found on PATH."
  echo "Install git and retry."
  exit 1
fi

mkdir -p "$PLUGIN_DIR"
mkdir -p "$SKILLS_DIR"

TARGET="${PLUGIN_DIR}/${PLUGIN_NAME}"

if [ -d "$TARGET" ]; then
  echo "Already installed — updating..."
  git -C "$TARGET" pull
else
  echo "Cloning repository..."
  git clone "$REPO_URL" "$TARGET"
fi

echo "Linking skills to ~/.claude/skills/..."
for skill_dir in "$TARGET/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  link_path="${SKILLS_DIR}/${skill_name}"

  if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
    echo "  ! ${skill_name} exists and is not a symlink — skipping"
    continue
  fi

  if [ -L "$link_path" ]; then
    rm "$link_path"
  fi

  ln -s "$skill_dir" "$link_path"
  echo "  ✓ ${skill_name}"
done

echo ""
echo "✓ Claude Onboarding Agent installed successfully!"
echo ""
echo "Start a new Claude Code session and run: /onboarding"
