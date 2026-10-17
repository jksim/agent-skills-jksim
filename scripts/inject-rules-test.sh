#!/usr/bin/env bash
# Tests for inject-rules.sh (R1–R5).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/inject-rules.sh"
CLAUDE_PLUGIN_ROOT="$(dirname "$here")"
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
trap 'rm -rf "$CLAUDE_PROJECT_DIR"' EXIT

fails=0
ok() { echo "  ok   $1"; }
no() { echo "  FAIL $1"; fails=$((fails + 1)); }
run() { jq -cn --arg e "$1" '{hook_event_name: $e, source: "startup"}' | "$script"; }

for e in SessionStart SubagentStart; do
  out=$(run "$e")
  if [[ $(jq -r .hookSpecificOutput.hookEventName <<<"$out") == "$e" ]]; then ok "R $e event"; else no "R $e event"; fi
  if jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "## 4. Short comments"; then ok "R $e rules"; else no "R $e rules"; fi
  if jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "## 8. Rejected scope stays rejected"; then ok "R $e rule 8"; else no "R $e rule 8"; fi
  if jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "# Team overrides for agent-skills"; then ok "U1 $e overrides"; else no "U1 $e overrides"; fi
done

out=$(run PreToolUse)
if [[ -z "$out" ]]; then ok "R3 other event"; else no "R3 other event"; fi

tmp=$(mktemp -d)
out=$(jq -cn '{hook_event_name: "SessionStart"}' | CLAUDE_PLUGIN_ROOT="$tmp" "$script") && rc=0 || rc=$?
if ((rc == 0)) && jq -r .systemMessage <<<"$out" | grep -qF "$tmp/rules/JARRETTS-RULES.md"; then ok "R4 missing file"; else no "R4 missing file"; fi

tmp=$(mktemp -d)
mkdir -p "$tmp/rules" && cp "$CLAUDE_PLUGIN_ROOT/rules/JARRETTS-RULES.md" "$tmp/rules/"
out=$(jq -cn '{hook_event_name: "SessionStart"}' | CLAUDE_PLUGIN_ROOT="$tmp" "$script")
if jq -e '(.hookSpecificOutput.additionalContext | contains("## 4. Short comments")) and (.systemMessage | contains("PROCESS-OVERRIDES.md"))' <<<"$out" >/dev/null; then ok "R4 one file missing"; else no "R4 one file missing"; fi
rm -rf "$tmp"
tmp=$(mktemp -d)
mkdir -p "$tmp/with space/scripts" "$tmp/with space/rules"
cp "$script" "$tmp/with space/scripts/"
cp "$CLAUDE_PLUGIN_ROOT"/rules/*.md "$tmp/with space/rules/"
out=$(jq -cn '{hook_event_name: "SessionStart"}' | env -u CLAUDE_PLUGIN_ROOT "$tmp/with space/scripts/inject-rules.sh")
if jq -r .hookSpecificOutput.additionalContext <<<"$out" | grep -q "## 0. Process"; then ok "R root unset, path with space"; else no "R root unset, path with space"; fi
rm -rf "$tmp"

size=$(wc -c <"$CLAUDE_PLUGIN_ROOT/rules/JARRETTS-RULES.md")
ctx=$(run SessionStart | jq -r .hookSpecificOutput.additionalContext | wc -c)
if ((size <= 8000)); then ok "R5 rules $size <= 8000"; else no "R5 rules $size <= 8000"; fi
if ((ctx < 9000)); then ok "U1 context $ctx < 9000"; else no "U1 context $ctx < 9000"; fi

((fails == 0))
