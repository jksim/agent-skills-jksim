#!/usr/bin/env bash
# Add Jarrett's rules to the context of each session and subagent.
set -euo pipefail

if ! command -v jq >/dev/null; then
  printf '{"systemMessage":"agent-skills-jksim: jq not found. Rules not loaded."}\n'
  exit 0
fi

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
files=("$root/rules/JARRETTS-RULES.md" "$root/rules/PROCESS-OVERRIDES.md")
event=$(jq -r '.hook_event_name // empty') || exit 0

case "$event" in
  SessionStart | SubagentStart) ;;
  *) exit 0 ;;
esac

text=""
missing=()
for f in "${files[@]}"; do
  if [[ -f "$f" ]]; then text+="$(cat "$f")"$'\n\n'; else missing+=("$f"); fi
done

msg=""
((${#missing[@]})) && msg="agent-skills-jksim: rules file not found: ${missing[*]}"
[[ -z "$text" ]] && { jq -cn --arg m "$msg" '{systemMessage: $m}'; exit 0; }

jq -cn --arg e "$event" --arg r "$text" --arg m "$msg" '{
  hookSpecificOutput: {
    hookEventName: $e,
    additionalContext: ("The agent-skills-jksim plugin is active. This team'"'"'s working rules follow.\n\n" + $r)
  }
} + (if $m == "" then {} else {systemMessage: $m} end)'
