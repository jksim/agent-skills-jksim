#!/usr/bin/env bash
# Repeat the team overrides that apply when an agent-skills skill or command starts.
set -euo pipefail

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
file="$root/rules/PROCESS-OVERRIDES.md"
input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")
name=$(jq -r '.command_name // .tool_input.skill // empty' <<<"$input")
[[ -f "$file" && "$name" == agent-skills:* ]] || exit 0

case "${name#agent-skills:}" in
  spec | spec-driven-development) sections=("Paths" "Spec stage: vocabulary") ;;
  plan | planning-and-task-breakdown | constraints | constraint-driven-development | documentation-and-adrs | interview-me | idea-refine) sections=("Paths") ;;
  build | incremental-implementation) sections=("Paths" "Send back (rule 0)" "Commits (rule 4)") ;;
  test | test-driven-development | review | code-review-and-quality | debugging-and-error-recovery | doubt-driven-development) sections=("Send back (rule 0)") ;;
  ship | shipping-and-launch | git-workflow-and-versioning) sections=("Commits (rule 4)") ;;
  *) exit 0 ;;
esac

text=""
for s in "${sections[@]}"; do
  part=$(awk -v h="## $s" '{sub(/[ \t\r]+$/, "")} $0 == h {on = 1; print; next} on && /^## / {exit} on' "$file")
  [[ -n "$part" ]] && text+="$part"$'\n\n'
done
[[ -z "$text" ]] && exit 0

jq -cn --arg e "$event" --arg n "$name" --arg t "$text" '{
  hookSpecificOutput: {
    hookEventName: $e,
    additionalContext: ("Team overrides for " + $n + " (agent-skills-jksim):\n\n" + $t)
  }
}'
