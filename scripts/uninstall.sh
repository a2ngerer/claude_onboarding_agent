#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="claude-onboarding-agent"
SKILLS_DIR="${HOME}/.claude/skills"
TARGET="${PLUGIN_DIR}/${PLUGIN_NAME}"
SKILLS_SOURCE="${TARGET}/skills"

echo "Uninstalling Claude Onboarding Agent..."

if [ -d "$TARGET" ]; then
  for skill_dir in "$SKILLS_SOURCE"/*/; do
    skill_name=$(basename "$skill_dir")
    link_path="${SKILLS_DIR}/${skill_name}"
    if [ -L "$link_path" ]; then
      link_target="$(readlink "$link_path")"
      if [[ "$link_target" != /* ]]; then
        if ! link_target="$(cd "$(dirname "$link_path")" && cd "$link_target" && pwd -P 2>/dev/null)"; then
          echo "  ! skipped skill: ${skill_name} (broken symlink)"
          continue
        fi
      fi
      expected_target="$(cd "$skill_dir" && pwd -P)"
      if [ "$link_target" != "$expected_target" ]; then
        echo "  ! skipped skill: ${skill_name} (symlink points outside plugin)"
        continue
      fi
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
