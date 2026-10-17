#!/usr/bin/env bash
# Opt-in end-to-end smoke test: real Claude sessions, checked on hook output and files. Not run by test.sh.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
up=${UPSTREAM_DIR:-$root/../agent-skills}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

dirs=(--plugin-dir "$root")
[[ -d "$up/skills" ]] && dirs=(--plugin-dir "$up" "${dirs[@]}")

echo "claude $(claude --version)"
echo "plugin $root"
[[ -d "$up/skills" ]] && echo "upstream $up" || echo "upstream: installed copy"

fails=0
# run <name> <prompt>: one session in a fresh git repo; stream saved to $work/<name>.jsonl
run() {
  local d="$work/$1"
  mkdir -p "$d" && git -C "$d" init -q && echo a >"$d/a.txt" && git -C "$d" add a.txt
  (cd "$d" && claude "${dirs[@]}" -p "$2" --permission-mode acceptEdits --allowedTools "Bash(git *)" \
    --max-turns 6 --output-format stream-json --verbose --include-hook-events </dev/null >"$work/$1.jsonl" 2>"$work/$1.err") || true
}
# hook <name> <event prefix> <text>: a hook response for that event holds the text
hook() {
  jq -R -e --arg e "$2" --arg t "$3" 'fromjson? | select(.type == "system" and .subtype == "hook_response" and ((.hook_event_name // .hook_name // "") | startswith($e))) | tostring | select(contains($t))' "$work/$1.jsonl" >/dev/null 2>&1
}
result() { if "${@:2}"; then echo "  ok   $1"; else echo "  FAIL $1"; fails=$((fails + 1)); fi; }

run e1 "Say OK."
result "E1 rules in session" hook e1 SessionStart "## 4. Short comments"

run e2 "Use the Agent tool to start a general-purpose subagent that only says OK. Then say DONE."
result "E2 rules in subagent" hook e2 SubagentStart "## 8. Rejected scope"

run e3 "Run this Bash command: git commit -m wip"
result "E3 commit warning" hook e3 PreToolUse "commit-check (rule 4)"

run e4 "Run this one Bash command: git add a.txt && git commit -m wip"
result "E4 commit warning, chained command" hook e4 PreToolUse "commit-check (rule 4)"

run g1 "Use the Write tool to create SPEC.md in the project root with the line '# Spec'. Do not write any other file."
result "G1 path guard denies" hook g1 PreToolUse ".claude-work/spec/SPEC.md"
result "G1 no root SPEC.md" test -s "$work/g1.jsonl" -a ! -e "$work/g1/SPEC.md"

run u3 "/agent-skills:spec a CLI that prints hello. Reply with one question only. Do not write files."
result "U3 override reminder" hook u3 UserPromptExpansion "Team overrides for agent-skills:spec"

if ((fails)); then
  echo "e2e-smoke: $fails failed (streams kept in $work)"
  trap - EXIT
  exit 1
fi
echo "e2e-smoke: all passed"
