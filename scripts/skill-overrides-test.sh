#!/usr/bin/env bash
# Tests for skill-overrides.sh (U2, U3).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/skill-overrides.sh"
CLAUDE_PLUGIN_ROOT="$(dirname "$here")"
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
trap 'rm -rf "$CLAUDE_PROJECT_DIR"' EXIT

fails=0
skill() { jq -cn --arg s "$1" '{hook_event_name: "PreToolUse", tool_name: "Skill", tool_input: {skill: $s}}' | "$script"; }
cmd() { jq -cn --arg c "$1" '{hook_event_name: "UserPromptExpansion", expansion_type: "slash_command", command_name: $c}' | "$script"; }
has() {
  if jq -e --arg w "$3" '.hookSpecificOutput.additionalContext | contains($w)' <<<"$2" >/dev/null 2>&1; then
    echo "  ok   $1"
  else
    echo "  FAIL $1: $2"; fails=$((fails + 1))
  fi
}
lacks() {
  if ! jq -e --arg w "$3" '.hookSpecificOutput.additionalContext | contains($w)' <<<"$2" >/dev/null 2>&1; then
    echo "  ok   $1"
  else
    echo "  FAIL $1"; fails=$((fails + 1))
  fi
}
quiet() { if [[ -z "$2" ]]; then echo "  ok   $1"; else echo "  FAIL $1: $2"; fails=$((fails + 1)); fi; }

out=$(skill agent-skills:spec-driven-development)
has "U2 spec skill paths" "$out" ".claude-work/spec/SPEC.md"
has "U2 spec skill vocabulary" "$out" "## Spec stage: vocabulary"
lacks "U2 spec skill no commits" "$out" "## Commits"
has "U2 plan paths" "$(skill agent-skills:planning-and-task-breakdown)" ".claude-work/tasks/plan-<id>.md"
has "U2 constraints path" "$(skill agent-skills:constraint-driven-development)" ".claude-work/docs/CONSTRAINTS.md"
has "U2 adr path" "$(skill agent-skills:documentation-and-adrs)" ".claude-work/docs/adr/"
has "U2 build send back" "$(skill agent-skills:incremental-implementation)" "## Send back (rule 0)"
has "U2 tdd send back" "$(skill agent-skills:test-driven-development)" "## Send back (rule 0)"
has "U2 git rule 4" "$(skill agent-skills:git-workflow-and-versioning)" "## Commits (rule 4)"
quiet "U2 other upstream skill" "$(skill agent-skills:frontend-ui-engineering)"
quiet "U2 own plugin skill" "$(skill agent-skills-jksim:commit-hygiene)"
quiet "U2 unrelated skill" "$(skill dataviz)"

out=$(cmd agent-skills:spec)
has "U3 command event" "$out" ".claude-work/spec/SPEC.md"
if [[ $(jq -r .hookSpecificOutput.hookEventName <<<"$out") == UserPromptExpansion ]]; then echo "  ok   U3 command hookEventName"; else echo "  FAIL U3 command hookEventName"; fails=$((fails + 1)); fi
if [[ $(skill agent-skills:spec | jq -r .hookSpecificOutput.hookEventName) == PreToolUse ]]; then echo "  ok   U3 skill hookEventName"; else echo "  FAIL U3 skill hookEventName"; fails=$((fails + 1)); fi
quiet "U3 command other" "$(cmd agent-skills:webperf)"

has "U2 build rule 4" "$(skill agent-skills:incremental-implementation)" "## Commits (rule 4)"
has "U2 interview-me paths" "$(skill agent-skills:interview-me)" ".claude-work/docs/intent/"

# Each section the script names must be a heading in the overrides file.
while IFS= read -r s; do
  if grep -qxF "## $s" "$CLAUDE_PLUGIN_ROOT/rules/PROCESS-OVERRIDES.md"; then echo "  ok   U2 heading: $s"; else echo "  FAIL U2 heading missing: $s"; fails=$((fails + 1)); fi
done < <(grep -o 'sections=([^)]*)' "$script" | grep -o '"[^"]*"' | tr -d '"' | sort -u)

((fails == 0))
