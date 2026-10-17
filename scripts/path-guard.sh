#!/usr/bin/env bash
# Block new working files at upstream root paths. Give the team path instead.
set -euo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
proj=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<<"$input")}
[[ -z "$file" || -z "$proj" || "$file" != /* ]] && exit 0
[[ -e "$file" ]] && exit 0
rel=${file#"${proj%/}"/}
[[ "$rel" == "$file" ]] && exit 0
# A project with its own ADR folder keeps it.
[[ "$rel" == docs/decisions/* && -d "$proj/docs/decisions" ]] && exit 0

# Not spec/*: RSpec and other test layouts use spec/.

case "$rel" in
  SPEC.md | docs/SPEC.md) to=".claude-work/spec/SPEC.md" ;;
  SPEC-*.md) to=".claude-work/spec/$rel" ;;
  CAPABILITY-MAP.md) to=".claude-work/spec/CAPABILITY-MAP.md" ;;
  tasks/plan.md) to=".claude-work/tasks/plan-<id>.md" ;;
  tasks/todo.md) to=".claude-work/tasks/todo-<id>.md" ;;
  CONSTRAINTS.md) to=".claude-work/docs/CONSTRAINTS.md" ;;
  docs/decisions/*) to=".claude-work/docs/adr/${rel#docs/decisions/}" ;;
  *) exit 0 ;;
esac

jq -cn --arg r "$rel" --arg t "$to" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("The team keeps working files in .claude-work/. Write " + $t + " instead of " + $r + ". See the Paths table in the team overrides.")
  }
}'
