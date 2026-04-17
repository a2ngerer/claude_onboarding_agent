#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="claude-onboarding-agent"
SKILLS_DIR="${HOME}/.claude/skills"
TARGET="${PLUGIN_DIR}/${PLUGIN_NAME}"

echo "Uninstalling Claude Onboarding Agent..."

if [ -d "$TARGET" ]; then
  for skill_dir in "$TARGET/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    link_path="${SKILLS_DIR}/${skill_name}"
    if [ -L "$link_path" ]; then
      rm "$link_path"
      echo "  ✓ removed skill: ${skill_name}"
    fi
  done
  rm -rf "$TARGET"
  echo ""
  echo "✓ Claude Onboarding Agent removed successfully."
else
  echo "Not installed — nothing to remove."
fi
