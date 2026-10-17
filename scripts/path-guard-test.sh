#!/usr/bin/env bash
# Tests for path-guard.sh (U4).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/path-guard.sh"
CLAUDE_PLUGIN_ROOT="$(dirname "$here")"
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
trap 'rm -rf "$CLAUDE_PROJECT_DIR"' EXIT

fails=0
run() { jq -cn --arg f "$1" '{hook_event_name: "PreToolUse", tool_name: "Write", tool_input: {file_path: $f}}' | "$script"; }
denies() {
  local out
  out=$(run "$CLAUDE_PROJECT_DIR/$2")
  if jq -e --arg w "$3" '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains($w))' <<<"$out" >/dev/null 2>&1; then
    echo "  ok   $1"
  else
    echo "  FAIL $1: $out"; fails=$((fails + 1))
  fi
}
allows() {
  local out
  out=$(run "$2")
  if [[ -z "$out" ]]; then echo "  ok   $1"; else echo "  FAIL $1: $out"; fails=$((fails + 1)); fi
}

denies "U4 SPEC.md" SPEC.md ".claude-work/spec/SPEC.md"
denies "U4 SPEC-x.md" SPEC-billing.md ".claude-work/spec/SPEC-billing.md"
denies "U4 capability map" CAPABILITY-MAP.md ".claude-work/spec/CAPABILITY-MAP.md"
denies "U4 tasks/plan.md" tasks/plan.md ".claude-work/tasks/plan-<id>.md"
denies "U4 tasks/todo.md" tasks/todo.md ".claude-work/tasks/todo-<id>.md"
denies "U4 CONSTRAINTS.md" CONSTRAINTS.md ".claude-work/docs/CONSTRAINTS.md"
denies "U4 ADR" docs/decisions/0001-use-jq.md ".claude-work/docs/adr/0001-use-jq.md"
denies "U4 docs/SPEC.md" docs/SPEC.md ".claude-work/spec/SPEC.md"
allows "U4 spec/ dir" "$CLAUDE_PROJECT_DIR/spec/greet_spec.md"
allows "U4 team spec path" "$CLAUDE_PROJECT_DIR/.claude-work/spec/SPEC.md"
allows "U4 source file" "$CLAUDE_PROJECT_DIR/src/spec.ts"
allows "U4 nested SPEC.md" "$CLAUDE_PROJECT_DIR/pkg/SPEC.md"
allows "U4 outside project" "/tmp/SPEC.md"
touch "$CLAUDE_PROJECT_DIR/CONSTRAINTS.md"
allows "U4 existing root file" "$CLAUDE_PROJECT_DIR/CONSTRAINTS.md"
mkdir -p "$CLAUDE_PROJECT_DIR/docs/decisions" && touch "$CLAUDE_PROJECT_DIR/docs/decisions/0001.md"
allows "U4 new ADR in existing docs/decisions" "$CLAUDE_PROJECT_DIR/docs/decisions/0002.md"

((fails == 0))
