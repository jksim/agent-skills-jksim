#!/usr/bin/env bash
# Add Jarrett's rules to the context of each session and subagent.
set -euo pipefail

if ! command -v jq >/dev/null; then
  printf '{"systemMessage":"agent-skills-jksim: jq not found. Rules not loaded."}\n'
  exit 0
fi

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
rules="$root/rules/JARRETTS-RULES.md"
event=$(jq -r '.hook_event_name // empty')

case "$event" in
  SessionStart | SubagentStart) ;;
  *) exit 0 ;;
esac

if [[ ! -f "$rules" ]]; then
  jq -cn --arg p "$rules" '{systemMessage: ("agent-skills-jksim: rules file not found: " + $p)}'
  exit 0
fi

jq -cn --arg e "$event" --rawfile r "$rules" '{
  hookSpecificOutput: {
    hookEventName: $e,
    additionalContext: ("The agent-skills-jksim plugin is active. This team'"'"'s working rules follow.\n\n" + $r)
  }
}'
