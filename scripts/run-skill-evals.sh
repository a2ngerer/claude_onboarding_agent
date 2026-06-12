#!/usr/bin/env bash
# Skill trigger eval runner for claude-onboarding-agent.
#
# For every prompt in evals/<skill>.json, asks a judge model which skill it
# would invoke given only the catalog of skill names + frontmatter
# descriptions, then scores the prediction against the fixture expectation.
#
# Usage:
#   scripts/run-skill-evals.sh [--skill <name>] [--model <alias-or-id>]
#                              [--threshold <0..1>] [--jobs <n>] [--report <file>]
#
# Backends: Anthropic Messages API via curl when ANTHROPIC_API_KEY is set
# (CI), otherwise the local `claude` CLI in print mode with safe mode enabled
# so no project context, plugins, or hooks influence the judgment.
#
# Spec: docs/superpowers/specs/2026-06-12-skill-eval-harness-design.md

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVALS_DIR="$REPO_ROOT/evals"

MODEL="haiku"
THRESHOLD="0.90"
JOBS=4
ONLY_SKILL=""
REPORT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --skill)     ONLY_SKILL="$2"; shift 2 ;;
    --model)     MODEL="$2"; shift 2 ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --jobs)      JOBS="$2"; shift 2 ;;
    --report)    REPORT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required." >&2; exit 1; }
[ -d "$EVALS_DIR" ] || { echo "ERROR: $EVALS_DIR does not exist." >&2; exit 1; }

BACKEND="cli"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  BACKEND="api"
elif ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: need either ANTHROPIC_API_KEY (API backend) or the claude CLI on PATH." >&2
  exit 1
fi

api_model() {
  case "$1" in
    haiku)  echo "claude-haiku-4-5-20251001" ;;
    sonnet) echo "claude-sonnet-4-6" ;;
    opus)   echo "claude-opus-4-8" ;;
    fable)  echo "claude-fable-5" ;;
    *)      echo "$1" ;;
  esac
}

# --- Catalog: name + description from every SKILL.md frontmatter -------------
build_catalog() {
  local dir name desc
  for dir in "$REPO_ROOT"/skills/*/; do
    [ -f "$dir/SKILL.md" ] || continue
    name="$(sed -n '/^---$/,/^---$/s/^name:[[:space:]]*//p' "$dir/SKILL.md" | head -1)"
    desc="$(sed -n '/^---$/,/^---$/s/^description:[[:space:]]*//p' "$dir/SKILL.md" | head -1)"
    if [ -n "$name" ] && [ -n "$desc" ]; then
      printf -- '- %s: %s\n' "$name" "$desc"
    fi
  done
}
CATALOG="$(build_catalog)"
SKILL_NAMES="$(printf '%s\n' "$CATALOG" | sed 's/^- \([^:]*\):.*/\1/')"
[ -n "$CATALOG" ] || { echo "ERROR: could not build the skill catalog from skills/*/SKILL.md." >&2; exit 1; }

# --- Judge --------------------------------------------------------------------
judge() {
  local user_prompt="$1" full reply
  full="You are the skill router of a Claude Code plugin. Given the catalog of available skills below and a user message, decide which single skill you would invoke for that message, or none.

Catalog:
${CATALOG}

Reply with exactly one token: the skill name, or none. No punctuation, no explanation.

User message: ${user_prompt}"
  if [ "$BACKEND" = "api" ]; then
    reply="$(curl -sS --max-time 90 https://api.anthropic.com/v1/messages \
      -H "x-api-key: ${ANTHROPIC_API_KEY}" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$(jq -cn --arg m "$(api_model "$MODEL")" --arg p "$full" \
            '{model:$m, max_tokens:16, messages:[{role:"user",content:$p}]}')" \
      2>/dev/null | jq -r '.content[0].text // empty' 2>/dev/null || true)"
  else
    reply="$(CLAUDE_CODE_SAFE_MODE=1 claude -p --model "$MODEL" "$full" 2>/dev/null || true)"
  fi
  # Normalize: last non-empty line, strip quotes/backticks/periods, lowercase, trim.
  reply="$(printf '%s' "$reply" | awk 'NF{l=$0} END{print l}' \
    | tr -d '`".' | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if printf '%s\n' "$SKILL_NAMES" | grep -qx -- "$reply"; then
    printf '%s' "$reply"
  else
    printf 'none'
  fi
}

run_task() {
  # $1 = "idx<TAB>skill<TAB>type<TAB>prompt"
  local idx skill type prompt predicted outcome
  IFS="$(printf '\t')" read -r idx skill type prompt <<EOF
$1
EOF
  predicted="$(judge "$prompt")"
  if [ "$type" = "expect" ]; then
    [ "$predicted" = "$skill" ] && outcome=pass || outcome=fail
  else
    [ "$predicted" != "$skill" ] && outcome=pass || outcome=fail
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$skill" "$type" "$outcome" "$predicted" "$prompt" \
    > "$RUN_DIR/results/$idx"
}
export -f judge run_task api_model
export CATALOG SKILL_NAMES BACKEND MODEL

RUN_DIR="$(mktemp -d)"
export RUN_DIR
trap 'rm -rf "$RUN_DIR"' EXIT
mkdir -p "$RUN_DIR/results"

# --- Task list ----------------------------------------------------------------
idx=0
: > "$RUN_DIR/tasks.tsv"
for fixture in "$EVALS_DIR"/*.json; do
  [ -f "$fixture" ] || continue
  skill="$(jq -r '.skill' "$fixture")"
  if [ -n "$ONLY_SKILL" ] && [ "$skill" != "$ONLY_SKILL" ]; then
    continue
  fi
  while IFS= read -r p; do
    idx=$((idx + 1))
    printf '%s\t%s\t%s\t%s\n' "$idx" "$skill" "expect" "$p" >> "$RUN_DIR/tasks.tsv"
  done < <(jq -r '.should_trigger[]' "$fixture")
  while IFS= read -r p; do
    idx=$((idx + 1))
    printf '%s\t%s\t%s\t%s\n' "$idx" "$skill" "reject" "$p" >> "$RUN_DIR/tasks.tsv"
  done < <(jq -r '.should_not_trigger[]' "$fixture")
done
total=$idx
[ "$total" -gt 0 ] || { echo "ERROR: no eval prompts found (check evals/ or --skill filter)." >&2; exit 1; }

echo "Running $total trigger evals (backend: $BACKEND, model: $MODEL, jobs: $JOBS)..."
tr '\n' '\0' < "$RUN_DIR/tasks.tsv" \
  | xargs -0 -P "$JOBS" -I{} bash -c 'run_task "$1"' _ {}

completed="$(ls "$RUN_DIR/results" | wc -l | tr -d ' ')"
if [ "$completed" -ne "$total" ]; then
  echo "WARNING: $((total - completed)) of $total tasks produced no result (backend errors)." >&2
fi

cat "$RUN_DIR"/results/* > "$RUN_DIR/all.tsv"

# --- Summary -------------------------------------------------------------------
echo
printf '%-26s %8s %8s %10s\n' "skill" "pass" "total" "rate"
printf '%-26s %8s %8s %10s\n' "-----" "----" "-----" "----"
awk -F'\t' '
  { tot[$1]++; if ($3 == "pass") ok[$1]++ }
  END {
    for (s in tot) printf "%-26s %8d %8d %9.0f%%\n", s, ok[s], tot[s], 100 * ok[s] / tot[s]
  }' "$RUN_DIR/all.tsv" | sort

failures="$(awk -F'\t' '$3 == "fail"' "$RUN_DIR/all.tsv" || true)"
if [ -n "$failures" ]; then
  echo
  echo "Failures (skill | type | predicted | prompt):"
  printf '%s\n' "$failures" | awk -F'\t' '{ printf "  %s | %s | %s | %s\n", $1, $2, $4, $5 }'
fi

overall="$(awk -F'\t' '{ t++; if ($3 == "pass") p++ } END { printf "%.4f", (t ? p / t : 0) }' "$RUN_DIR/all.tsv")"
echo
echo "Overall pass rate: $overall (threshold: $THRESHOLD)"

if [ -n "$REPORT" ]; then
  jq -Rn --arg model "$MODEL" --arg backend "$BACKEND" --argjson threshold "$THRESHOLD" \
    --argjson overall "$overall" '
    [inputs | split("\t") | {skill: .[0], type: .[1], outcome: .[2], predicted: .[3], prompt: .[4]}] as $rows |
    {
      model: $model,
      backend: $backend,
      threshold: $threshold,
      overall_pass_rate: $overall,
      skills: ($rows | group_by(.skill) | map({
        skill: .[0].skill,
        total: length,
        pass: (map(select(.outcome == "pass")) | length)
      })),
      failures: ($rows | map(select(.outcome == "fail")))
    }' < "$RUN_DIR/all.tsv" > "$REPORT"
  echo "Report written to $REPORT"
fi

awk -v o="$overall" -v t="$THRESHOLD" 'BEGIN { exit (o + 0 >= t + 0 ? 0 : 1) }'
