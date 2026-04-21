#!/usr/bin/env bash
# PostToolUse hook for claude_onboarding_agent. warns Claude when an edited file has known dependents
# that usually must be updated together. Emits additionalContext via JSON.
# Input: tool call JSON on stdin. Output: JSON on stdout (or nothing).

set -u

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

REPO="/Users/angeral/Repositories/claude_onboarding_agent"
REL="${FILE#$REPO/}"

emit() {
  jq -cn --arg ctx "$1" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
}

case "$REL" in
  skills/_shared/installation.md)
    emit "Shared installation protocol was modified. All 7 setup skills reference this file. Verify: (1) no setup skill (skills/coding-setup, knowledge-base-setup, office-setup, research-setup, content-creator-setup, devops-setup, design-setup) uses outdated step numbers (P1–P5) or variable names (e.g. \`superpowers_installed\`, \`superpowers_method\`, \`superpowers_scope\`). (2) docs/superpowers/specs/2026-04-17-installation-protocol.md still reflects the current contract."
    ;;
  skills/onboarding/SKILL.md)
    emit "Orchestrator skill was modified. Verify: (1) every path it offers in Step 3 / Step 5 corresponds to an existing skill folder under skills/. (2) README.md 'What's Inside' table matches the path list."
    ;;
  skills/*/SKILL.md)
    skill=$(printf '%s' "$REL" | sed -E 's#skills/([^/]+)/SKILL\.md#\1#')
    emit "Skill '$skill' was modified. If this is a new skill or its slash-command name/description changed, verify: (1) .claude-plugin/plugin.json lists it in skills[] AND commands[]. (2) skills/onboarding/SKILL.md offers it in Step 3 and Step 5. (3) README.md 'What's Inside' table includes it. (4) If it references the shared install protocol, variables match skills/_shared/installation.md."
    ;;
  .claude-plugin/plugin.json)
    emit "plugin.json was modified. If skills[] or commands[] changed, verify: (1) every referenced skill exists at skills/<name>/SKILL.md. (2) skills/onboarding/SKILL.md Step 3 and Step 5 still match. (3) README.md 'What's Inside' table still matches. (4) scripts/install.sh still works for the new skill set."
    ;;
  CLAUDE.md)
    emit "Project CLAUDE.md was modified. If 'Adding a New Skill' steps or 'Skill Authoring Rules' changed, verify: (1) README.md reflects the same conventions. (2) docs/superpowers/specs/2026-04-16-onboarding-agent-design.md is still consistent."
    ;;
  docs/superpowers/specs/*.md)
    emit "A design spec was modified. If decisions changed, verify the corresponding plan in docs/superpowers/plans/ and any affected SKILL.md files reflect the new contract."
    ;;
  scripts/install.sh|scripts/uninstall.sh)
    emit "Install/uninstall script was modified. Verify: (1) README.md installation instructions still match. (2) docs/installation.md (if present) still matches. (3) .claude-plugin/plugin.json skills/commands arrays are consistent with what the script installs."
    ;;
esac

exit 0
